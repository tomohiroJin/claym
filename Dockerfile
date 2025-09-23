##############################
# Dockerfile for Claym AI development container
#
# This image installs Ubuntu 24.10 together with stable
# versions of Node.js and Python.  It preinstalls Anthropic’s
# Claude Code CLI, OpenAI’s Codex CLI and Google’s Gemini CLI,
# along with the Model Context Protocol (MCP) servers used in
# the project.  Modern command‑line tools and Oh My Zsh are
# included to provide a comfortable shell environment.  See
# README or devcontainer.json for details on how to use this
# container.
##############################

FROM ubuntu:24.10

ENV DEBIAN_FRONTEND=noninteractive
# Use /workspace as the default working directory.  VS Code will mount
# the project here when attaching to the container.  All AI tools
# reference relative paths from this folder.
WORKDIR /workspace

# ----------------------------------------------------------------------------
# Base system configuration
#
# Install essential packages, compilers and libraries required by various
# components.  Many MCP servers depend on Python and Node.js, and
# Playwright requires numerous system libraries to run headless
# Chromium.  We also install modern CLI tools (fzf, zoxide, ripgrep,
# bat, fd-find, eza, tree, tldr) and fonts for a pleasant terminal
# experience.

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        sudo \
        git \
        git-lfs \
        curl \
        wget \
        jq \
        tree \
        fzf \
        zoxide \
        ripgrep \
        bat \
        fd-find \
        eza \
        tldr \
        zsh \
        locales \
        fonts-powerline \
        python3 \
        python3-pip \
        python3-venv \
        python3-dev \
        # Libraries required by ImageSorcery (OpenCV) and Playwright
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
        libasound2 \
        libx11-xcb1 \
        libxss1 \
        libxkbcommon0 \
        xvfb \
        libx11-6 \
        dbus-x11 \
        unzip \
    && rm -rf /var/lib/apt/lists/*

# Configure locale and timezone.  VS Code uses en_US.UTF-8 by default but
# you can change this to ja_JP.UTF-8 or another locale if you prefer.
RUN locale-gen en_US.UTF-8 \
    && update-locale LANG=en_US.UTF-8 \
    && ln -sf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime \
    && echo "Asia/Tokyo" > /etc/timezone

# Set locale and timezone environment variables.  We default to
# English to avoid surprises in logs or error messages.  Adjust
# these if you prefer a different language.  The timezone matches
# the user’s location (Asia/Tokyo).  See user bio for details.
ENV LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    TZ=Asia/Tokyo

# ----------------------------------------------------------------------------
# Node.js installation
#
# Install Node.js 20 from NodeSource.  This version satisfies the
# requirements of Claude Code, Codex CLI and Gemini CLI.  After
# installation, update npm to the latest version to avoid warnings.

RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get update \
    && apt-get install -y --no-install-recommends nodejs \
    && npm install -g npm@latest \
    && rm -rf /var/lib/apt/lists/*

# ----------------------------------------------------------------------------
# Install global Node.js tools
#
# Install the three AI CLIs plus several MCP servers.  Versions are
# deliberately left at @latest to ensure the user gets recent stable
# updates.  If you require pinned versions, replace @latest with a
# specific version number.

RUN npm install -g \
        @anthropic-ai/claude-code@latest \
        @openai/codex@latest \
        @google/gemini-cli@latest \
        @playwright/mcp@latest \
        @modelcontextprotocol/server-filesystem@latest \
        firecrawl-mcp@latest

# Pre-download Playwright browsers and their system dependencies so
# there’s no delay the first time the MCP is used.  The --with-deps
# flag also installs any missing apt packages required by the
# Playwright runtime (it will silently skip ones already present).
RUN npx playwright install chromium --with-deps

# ----------------------------------------------------------------------------
# Python environment and MCP servers
#
# Install Python MCP servers via pip.  The no‑cache option reduces
# image size.  Serena requires uv to run; we install uv separately
# below.  After installing ImageSorcery MCP, run its post‑install
# command to download machine learning models used for object
# detection and OCR.  These models are cached inside the image so
# they don’t download on first use.

RUN pip install --no-cache-dir \
        markitdown-mcp \
        imagesorcery-mcp \
        mcp-github \
    && imagesorcery-mcp --post-install

# Install uv – a fast Python package manager used by Serena MCP.  Its
# installer downloads a static binary into ~/.local/bin.  We
# explicitly set the install prefix to /usr/local so that uv is
# accessible to all users without modifying PATH.  See Serena’s
# documentation for more details on uv usage.
RUN curl -LsSf https://astral.sh/uv/install.sh | sh -s -- --install-dir /usr/local/bin

# Clone Serena into /opt.  We clone the project but let uv manage its
# dependencies at runtime.  Using uv run ensures Serena’s Python
# dependencies are installed in an isolated environment separate from
# the system interpreter.  You can update Serena by pulling the
# repository and re‑registering the MCP server.
RUN git clone https://github.com/oraios/serena.git /opt/serena

# Add ~/.local/bin to PATH for uv and other user installed tools.
ENV PATH="/root/.local/bin:$PATH"

# ----------------------------------------------------------------------------
# Oh My Zsh and user setup
#
# Install Oh My Zsh for the root user.  A user named "vscode" is
# created with passwordless sudo so that VS Code can run commands.
# We copy the Oh My Zsh configuration from root to the vscode
# user and set up a few aliases and zoxide initialization.  We
# also alias bat and fd to their actual Ubuntu names (batcat and
# fdfind) for convenience.

RUN sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended \
    && useradd -m -s /bin/zsh vscode \
    && echo 'vscode ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers \
    && cp -r /root/.oh-my-zsh /home/vscode/.oh-my-zsh \
    && cp /root/.zshrc /home/vscode/.zshrc \
    && echo 'alias bat="batcat"' >> /home/vscode/.zshrc \
    && echo 'alias fd="fdfind"' >> /home/vscode/.zshrc \
    && echo 'eval "$(zoxide init zsh)"' >> /home/vscode/.zshrc \
    && chown -R vscode:vscode /home/vscode

# ----------------------------------------------------------------------------
# Copy helper scripts
#
# The post-create-setup.sh script registers MCP servers with the
# AI CLIs.  devcontainer.json executes this after the container
# is created.  You can edit this script to customise the list of
# MCPs or adjust registration commands.

COPY post-create-setup.sh /usr/local/bin/post-create-setup.sh
RUN chmod +x /usr/local/bin/post-create-setup.sh

# Default to the non‑root user for interactive shells.  VS Code
# Dev Containers will honour this user if remoteUser is set in
# devcontainer.json (not required here because this USER directive
# applies globally).
USER vscode

CMD ["/bin/zsh"]