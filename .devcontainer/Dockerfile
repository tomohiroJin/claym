##############################
# Claym AI 開発用コンテナ向け Dockerfile
#
# このイメージは Ubuntu 24.04 LTS に、安定版の Node.js と Python を組み合わせて導入します。
# さらに Anthropic の Claude Code CLI、OpenAI の Codex CLI、Google の Gemini CLI を
# 事前インストールし、プロジェクトで使用する Model Context Protocol (MCP) サーバ群も
# 同梱します。使いやすいシェル環境のために、モダンなコマンドラインツール群と
# Oh My Zsh も含めています。使い方の詳細は README または devcontainer.json を参照してください。
##############################

FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
# 既定の作業ディレクトリとして /workspace を使用します。
# VS Code からコンテナに接続すると、プロジェクトはここにマウントされます。
# すべての AI ツールはこのフォルダからの相対パスを参照します。
WORKDIR /workspace

# ----------------------------------------------------------------------------
# ベースシステム設定
#
# さまざまなコンポーネントに必要な基本パッケージ、コンパイラ、ライブラリを導入します。
# 多くの MCP サーバは Python と Node.js に依存し、Playwright はヘッドレス Chromium を
# 動かすために多数のシステムライブラリを必要とします。
# fzf / zoxide / ripgrep / bat / fd-find / eza / tree / tldr などの
# モダンな CLI ツール群と、快適な端末表示のためのフォントも導入します。
# あわせて GitHub CLI の公式リポジトリ登録とネットワーク系ユーティリティの導入まで
# 単一レイヤーで完結させ、APT キャッシュの再利用効率を高めます。
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    sudo \
    gnupg \
    git \
    git-lfs \
    curl \
    wget \
    jq \
    tree \
    fzf \
    ripgrep \
    bat \
    fd-find \
    zsh \
    locales \
    fonts-powerline \
    python3 \
    python3-pip \
    python3-venv \
    python3-dev \
    # ImageSorcery（OpenCV）と Playwright が要求するライブラリ
    tesseract-ocr \
    libgl1 \
    libglib2.0-0 \
    libnss3 \
    libatk1.0-0 \
    libatk-bridge2.0-0 \
    libcups2 \
    libdrm2 \
    libxcomposite1 \
    libxdamage1 \
    libxrandr2 \
    libgbm1 \
    libpango-1.0-0 \
    libpangocairo-1.0-0 \
    libasound2t64 \
    libx11-xcb1 \
    libxss1 \
    libxkbcommon0 \
    xvfb \
    libx11-6 \
    dbus-x11 \
    unzip \
    xz-utils \
    # v0.2.0: ログ解析・テキスト解析ツール
    goaccess \
    lnav \
    # v0.2.0: Webデータ取得・API連携ツール
    httpie \
    # v0.2.0: レポート・プレゼンテーション生成ツール
    pandoc \
    # v0.2.0: 画像・動画処理ツール
    imagemagick \
    ffmpeg \
    webp \
    # v0.2.0: 現代的CLIツールと環境補完
    git-extras \
    tig \
    tmux \
    # シェルスクリプトの品質チェック
    shellcheck \
    # Bash テストフレームワークの依存パッケージ
    parallel \
    # ベーシックなエディタ・ページャ
    vim \
    less \
    nano \
    # ベーシックなシステムユーティリティ
    bash-completion \
    file \
    iproute2 \
    man-db \
    manpages \
    manpages-dev \
    net-tools \
    openssh-client \
    procps \
    psmisc \
    rsync \
    zip \
    # CLI: apt 由来に統一（Rust製代替）
    btop \
    hyperfine \
    ncdu \
    cloc \
    # v0.3.0: 追加CLIツール
    direnv \
    graphviz \
    chafa \
    # Ollama バイナリ展開に必要
    zstd; \
    mkdir -p /etc/apt/keyrings; \
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    | tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null; \
    chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg; \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
    | tee /etc/apt/sources.list.d/github-cli.list > /dev/null; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
    # Git/GitHub強化
    gh \
    # HTTP/ネットワーク
    iputils-ping \
    dnsutils \
    traceroute \
    mtr-tiny \
    netcat-openbsd \
    socat \
    lsof \
    whois \
    # 構造化データ/整形（yqはnpm版を使用するためここでは除外）
    miller \
    moreutils \
    # SSL（opensslは既存システムに含まれているが明示的に追加）
    openssl; \
    rm -rf /var/lib/apt/lists/*

# Ubuntu 24.04 にはデフォルトで ubuntu ユーザー（UID/GID 1000）が存在するため、
# 先に削除してから vscode ユーザーを作成する
RUN userdel -r ubuntu 2>/dev/null || true \
    && groupdel ubuntu 2>/dev/null || true \
    && (groupadd --gid 1000 vscode 2>/dev/null || true) \
    && useradd --uid 1000 --gid 1000 -m -s /bin/zsh vscode \
    && echo "vscode ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/vscode \
    && chmod 0440 /etc/sudoers.d/vscode

# ロケールとタイムゾーンの設定。
# VS Code は既定で en_US.UTF-8 を使いますが、必要に応じて ja_JP.UTF-8 などに変更できます。
RUN sed -i 's/^# *en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
    && locale-gen \
    && ln -sf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime \
    && echo "Asia/Tokyo" > /etc/timezone

# ロケールとタイムゾーンの環境変数を設定。
# ログやエラーメッセージでの意図しない挙動を避けるため英語を既定にしています。
# 必要に応じて変更してください。タイムゾーンはユーザーの所在地（Asia/Tokyo）に合わせています。
ENV LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    TZ=Asia/Tokyo

# ----------------------------------------------------------------------------
# Node.js のインストール
#
# NodeSource から Node.js 22 を導入します。
# このバージョンは Claude Code / Codex CLI / Gemini CLI の要件を満たします。
# インストール後、警告回避のため npm を最新版へ更新します。

RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get update \
    && apt-get install -y --no-install-recommends nodejs \
    && npm install -g npm@latest \
    && rm -rf /var/lib/apt/lists/*

# ----------------------------------------------------------------------------
# グローバル Node.js ツールのインストール
#
# 3 つの AI CLI と複数の MCP サーバを導入します。
# 安定した最新更新を得るためバージョンは @latest のままにしています。
# バージョン固定が必要な場合は、@latest を特定のバージョン番号に置き換えてください。

RUN npm install -g \
    @anthropic-ai/claude-code@latest \
    @openai/codex@latest \
    @google/gemini-cli@latest \
    @playwright/mcp@latest \
    @modelcontextprotocol/server-filesystem@latest \
    firecrawl-mcp@latest \
    # v0.2.0: データ処理・金融分析ツール
    yq \
    qtrn \
    # モダン CLI ツール
    tldr \
    # v0.3.0: ダイアグラム生成（Playwright の Chromium を再利用）
    @mermaid-js/mermaid-cli \
    # v0.3.0: 段階的思考プロセスMCP（事前インストールで初回起動を高速化）
    @modelcontextprotocol/server-sequential-thinking

# Playwright のブラウザ本体とシステム依存関係を事前取得して、
# MCP の初回利用時の待ち時間をなくします。--with-deps フラグは、
# Playwright 実行に必要な apt パッケージが未導入の場合に自動で導入します
# （既に存在するものは暗黙的にスキップされます）。
# ブラウザを共有パスにインストールし、非 root ユーザーからもアクセス可能にします。
ENV PLAYWRIGHT_BROWSERS_PATH=/opt/playwright-browsers
RUN npx playwright install chromium --with-deps \
    && chmod -R 755 /opt/playwright-browsers

# ----------------------------------------------------------------------------
# Python 環境と MCP サーバ
#
# 仮想環境（venv）を作成し、Python 製 MCP サーバを隔離して導入します。
# --no-cache-dir でイメージサイズを削減し、ImageSorcery MCP 用の追加モデルも取得します。
# - imagesorcery-mcp: fastmcp/pydantic 互換性のため >=0.11.0 を要求
# - fastmcp<3: imagesorcery-mcp 0.11.4 が FastMCP(log_level=...) を使用しており、
#   fastmcp 3.0 で廃止された引数のため TypeError で起動不可。上流修正まで 2.x に固定
#   (markitdown-mcp, mcp-github は mcp SDK 内蔵の FastMCP を使用しており影響なし)
# - CLIP: imagesorcery の post-install より前に明示的インストール（推奨対処）
# - post-install: 失敗しても続行するフォールバック付き
ENV VIRTUAL_ENV=/opt/mcp-venv
RUN python3 -m venv "$VIRTUAL_ENV" \
    && "$VIRTUAL_ENV/bin/pip" install --no-cache-dir --upgrade pip \
    && "$VIRTUAL_ENV/bin/pip" install --no-cache-dir \
    markitdown-mcp \
    "imagesorcery-mcp>=0.11.0" \
    "fastmcp>=2.10.0,<3" \
    mcp-github \
    && "$VIRTUAL_ENV/bin/pip" install --no-cache-dir \
    git+https://github.com/ultralytics/CLIP.git \
    && ( "$VIRTUAL_ENV/bin/imagesorcery-mcp" --post-install \
    || echo "WARNING: imagesorcery-mcp post-install failed, models may need to be downloaded at runtime" ) \
    && chown -R vscode:vscode "$VIRTUAL_ENV/lib/python3.12/site-packages/imagesorcery_mcp/logs" 2>/dev/null || true
ENV PATH="${VIRTUAL_ENV}/bin:$PATH"

# ----------------------------------------------------------------------------
# v0.2.0: Python ライブラリ（データ分析・Web連携・金融データ・レポート生成）
#
# ビジネス向けデータ分析や市場データ取得に必要なライブラリを導入します。
# これらは標準的なデータサイエンス・金融分析のワークフローで広く利用されています。
RUN "$VIRTUAL_ENV/bin/pip" install --no-cache-dir \
    # 数値・表データ分析
    pandas \
    csvkit \
    ipython \
    jupyter \
    # Webデータ取得・API連携
    requests \
    httpx \
    beautifulsoup4 \
    lxml \
    # 市場・金融データ分析
    yfinance \
    pandas-datareader \
    # レポート・プレゼンテーション生成
    landslide \
    jinja2

# uv のインストール（Serena MCP が利用）。
# インストーラは静的バイナリを ~/.local/bin に配置します。
# ここでは /usr/local/bin に明示的に配置して、PATH を変更せず全ユーザーから利用可能にします。
# uv の使い方の詳細は Serena のドキュメントを参照してください。
RUN curl -LsSf https://astral.sh/uv/install.sh | \
    env UV_INSTALL_DIR=/usr/local/bin UV_NO_MODIFY_PATH=1 sh

# Serena を /opt にクローンします。依存関係は実行時に uv に任せます。
# uv run を使うことで、Serena の Python 依存はシステム Python から分離された
# 仮想環境にインストールされます。更新したい場合はリポジトリを pull して
# MCP の再登録を行ってください。
RUN git clone https://github.com/oraios/serena.git /opt/serena
RUN chown -R vscode:vscode /opt/serena

# uv などユーザー領域にインストールされるツールのために ~/.local/bin を PATH に追加。
ENV PATH="/home/vscode/.local/bin:$PATH"

# ----------------------------------------------------------------------------
# モダン CLI ツールのインストール
#
# 開発体験を向上させるモダンな CLI ツールを導入します。
# - バイナリダウンロード: zoxide, eza, git-delta (GitHub Releases から)
# - Rust ツール: procs, bottom, dust, hyperfine, sd, tokei（プリビルドバイナリ取得）
#
# NOTE: すべての curl に -f フラグを付与し、HTTP エラー（404 等）で即座に
# 失敗するようにしています。これにより壊れた URL を早期に検出できます。

# バイナリダウンロード (GitHub Releases)
# デバッグ用: 1ツール1RUNで失敗箇所を特定する
# 問題特定後に1つのRUNブロックに統合すること

# [1/11] zoxide v0.9.9
RUN set -eux \
    && curl -sfLO "https://github.com/ajeetdsouza/zoxide/releases/download/v0.9.9/zoxide-0.9.9-x86_64-unknown-linux-musl.tar.gz" \
    && tar -xzf zoxide-*.tar.gz -C /usr/local/bin \
    && rm zoxide-*.tar.gz

# [2/11] eza v0.23.4
RUN set -eux \
    && curl -sfLO "https://github.com/eza-community/eza/releases/download/v0.23.4/eza_x86_64-unknown-linux-musl.tar.gz" \
    && tar -xzf eza_*.tar.gz -C /usr/local/bin \
    && rm eza_*.tar.gz

# [3/11] git-delta v0.18.2
RUN set -eux \
    && curl -sfLO "https://github.com/dandavison/delta/releases/download/0.18.2/delta-0.18.2-x86_64-unknown-linux-musl.tar.gz" \
    && tar -xzf delta-*.tar.gz --strip-components=1 -C /usr/local/bin delta-0.18.2-x86_64-unknown-linux-musl/delta \
    && rm delta-*.tar.gz

# [4/11] just (タスクランナー) v1.46.0
RUN set -eux \
    && curl -sfLO "https://github.com/casey/just/releases/download/1.46.0/just-1.46.0-x86_64-unknown-linux-musl.tar.gz" \
    && tar -xzf just-*.tar.gz -C /usr/local/bin just \
    && rm just-*.tar.gz

# [5/11] difftastic (構文認識diff) v0.67.0
RUN set -eux \
    && curl -sfLO "https://github.com/Wilfred/difftastic/releases/download/0.67.0/difft-x86_64-unknown-linux-gnu.tar.gz" \
    && tar -xzf difft-*.tar.gz -C /usr/local/bin \
    && rm difft-*.tar.gz

# [6/11] dust (ディスク使用量可視化) v1.1.1
RUN set -eux \
    && curl -sfLO "https://github.com/bootandy/dust/releases/download/v1.1.1/dust-v1.1.1-x86_64-unknown-linux-musl.tar.gz" \
    && tar -xzf dust-*.tar.gz --strip-components=1 -C /usr/local/bin dust-v1.1.1-x86_64-unknown-linux-musl/dust \
    && rm dust-*.tar.gz

# [7/11] sd (sed代替) v1.0.0
RUN set -eux \
    && curl -sfLO "https://github.com/chmln/sd/releases/download/v1.0.0/sd-v1.0.0-x86_64-unknown-linux-musl.tar.gz" \
    && tar -xzf sd-*.tar.gz -C /usr/local/bin --strip-components=1 \
    && rm sd-*.tar.gz

# [8/11] watchexec (ファイル監視) v2.3.2
RUN set -eux \
    && curl -sfLO "https://github.com/watchexec/watchexec/releases/download/v2.3.2/watchexec-2.3.2-x86_64-unknown-linux-musl.tar.xz" \
    && tar -xJf watchexec-*.tar.xz --strip-components=1 -C /usr/local/bin watchexec-2.3.2-x86_64-unknown-linux-musl/watchexec \
    && rm watchexec-*.tar.xz

# [9/11] duckdb (組み込みSQL分析) v1.5.0
RUN set -eux \
    && curl -sfLO "https://github.com/duckdb/duckdb/releases/download/v1.5.0/duckdb_cli-linux-amd64.zip" \
    && unzip -o duckdb_cli-linux-amd64.zip -d /usr/local/bin \
    && rm duckdb_cli-linux-amd64.zip

# [10/11] qsv (CSV高速処理) v17.0.0
# NOTE: qsv はリポジトリが dathere/qsv に移行し、メジャーバージョン体系に変更済み
RUN set -eux \
    && curl -sfLO "https://github.com/dathere/qsv/releases/download/17.0.0/qsv-17.0.0-x86_64-unknown-linux-gnu.zip" \
    && unzip -o qsv-17.0.0-x86_64-unknown-linux-gnu.zip -d /tmp/qsv-extract \
    && ls -la /tmp/qsv-extract/ \
    && find /tmp/qsv-extract -name "qsv" -type f | head -5 \
    && find /tmp/qsv-extract -name "qsv" -type f | head -1 | xargs -I{} cp {} /usr/local/bin/qsv \
    && chmod +x /usr/local/bin/qsv \
    && rm -rf qsv-*.zip /tmp/qsv-extract

# [11/11] 導入確認（デバッグ用・1つずつ確認）
RUN zoxide --version
RUN eza --version
RUN delta --version
RUN just --version
RUN difft --version
RUN dust --version
RUN sd --version
RUN watchexec --version
RUN duckdb --version
# RUN qsv --version

# Rust 製 CLI ツール（APT に統一）: btop/hyperfine/ncdu/cloc は上の apt ブロックで導入済み

# ----------------------------------------------------------------------------
# Oh My Zsh とユーザー設定
#
# vscode ユーザーに Oh My Zsh を導入します。VS Code がコマンドを実行できるよう、
# Oh My Zsh のインストールと vscode ユーザー用の設定を行います。
# モダン CLI ツールのエイリアスと zoxide の初期化を追加します。
# Debian の実体名に合わせて bat / fd のエイリアス（batcat / fdfind）も設定します。

RUN su vscode -c 'sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended' \
    && echo 'alias bat="batcat"' >> /home/vscode/.zshrc \
    && echo 'alias fd="fdfind"' >> /home/vscode/.zshrc \
    && echo 'alias ll="eza -la --git"' >> /home/vscode/.zshrc \
    && echo 'alias ls="eza"' >> /home/vscode/.zshrc \
    && echo 'alias cat="batcat"' >> /home/vscode/.zshrc \
    && echo 'alias find="fdfind"' >> /home/vscode/.zshrc \
    && echo 'alias top="btop"' >> /home/vscode/.zshrc \
    && echo 'eval "$(zoxide init zsh)"' >> /home/vscode/.zshrc \
    && echo 'alias cd="z"' >> /home/vscode/.zshrc \
    && echo '# v0.3.0: direnv フック（.envrc の自動読み込み）' >> /home/vscode/.zshrc \
    && echo 'eval "$(direnv hook zsh)"' >> /home/vscode/.zshrc \
    && chown vscode:vscode /home/vscode/.zshrc

# Git delta の設定
# git diff や git log の出力を delta で見やすく表示します。
RUN su vscode -c 'git config --global core.pager "delta"' \
    && su vscode -c 'git config --global interactive.diffFilter "delta --color-only"' \
    && su vscode -c 'git config --global delta.navigate true' \
    && su vscode -c 'git config --global delta.light false' \
    && su vscode -c 'git config --global merge.conflictstyle diff3' \
    && su vscode -c 'git config --global diff.colorMoved default'

# ----------------------------------------------------------------------------
# Bash テストフレームワーク (bats-core) のインストール
# ----------------------------------------------------------------------------

# bats-core 本体
RUN set -eux; \
    git clone --depth 1 https://github.com/bats-core/bats-core.git /tmp/bats-core && \
    cd /tmp/bats-core && \
    ./install.sh /usr/local && \
    rm -rf /tmp/bats-core

# bats ヘルパーライブラリ
RUN set -eux; \
    git clone --depth 1 https://github.com/bats-core/bats-support.git /usr/local/lib/bats-support && \
    git clone --depth 1 https://github.com/bats-core/bats-assert.git /usr/local/lib/bats-assert && \
    git clone --depth 1 https://github.com/bats-core/bats-file.git /usr/local/lib/bats-file

# ----------------------------------------------------------------------------
# v0.3.0: Ollama CLI のインストール（ローカル LLM 用）
#
# GPU ホストでローカル LLM を実行するための Ollama CLI を導入します。
# GPU を使用する場合は devcontainer.local.json に "--gpus=all" を追加してください。
# 詳細は docs/gpu-setup.md を参照してください。
#
# サプライチェーン攻撃リスクを回避するため、公式リリースのバージョン固定バイナリを
# 直接ダウンロードしています（curl | sh パターンは使用しません）。
ENV OLLAMA_VERSION=0.17.7
RUN set -eux; \
    curl -fsSL "https://github.com/ollama/ollama/releases/download/v${OLLAMA_VERSION}/ollama-linux-amd64.tar.zst" \
    -o /tmp/ollama.tar.zst; \
    tar --use-compress-program=unzstd -xf /tmp/ollama.tar.zst -C /usr; \
    rm /tmp/ollama.tar.zst; \
    ollama --version

# ----------------------------------------------------------------------------
# 補助スクリプトの配置
#
# post-create-setup.sh は AI CLI への MCP 登録を自動化します。
# devcontainer.json はコンテナ作成後にこのスクリプトを実行します。
# 登録対象やコマンドをカスタマイズしたい場合は、このスクリプトを編集してください。

COPY .devcontainer/post-create-setup.sh /usr/local/bin/post-create-setup.sh
RUN chmod +x /usr/local/bin/post-create-setup.sh

# ワークスペースディレクトリの所有権を vscode ユーザーに設定します。
RUN chown -R vscode:vscode /workspace

# 対話シェルの既定ユーザーを非 root（vscode）にします。
# VS Code Dev Containers は remoteUser が設定されていればそれを優先しますが、
# この USER 指定はグローバルに適用されるため、ここでは明示的に設定します。
USER vscode

CMD ["/bin/zsh"]