FROM buildpack-deps:bullseye
RUN sudo apt update && sudo apt -yq upgrade \
    && sudo apt -yq install zip unzip bash-completion build-essential ruby python3-pip \
    ninja-build htop iputils-ping jq less locales man-db nano vim ripgrep software-properties-common \
    clojure golang rustup cmale apache2 nginx nginx-extras nginx-doc php php-all-dev php-bcmath php-common \
    php-curl php-date php-fpm php-gd php-intl php-json php-mbstring php-mysql php-net-ftp php-pgsql php-pear php-sqlite3 php-xml \
    php-tokenizer php-zip sudo stow time emacs-nox multitail lsof ssl-cert fish zsh git git-lfs docker.io nodejs npm && locale-gen en_US.UTF-8

ENV LANG=en_US.UTF-8

### Gitpod user ###
RUN RUN useradd -l -u 33333 -G sudo -md /home/gitpod -s /bin/bash -p gitpod gitpod \
    # passwordless sudo for users in the 'sudo' group
    && sed -i.bkp -e 's/%sudo\s\+ALL=(ALL\(:ALL\)\?)\s\+ALL/%sudo ALL=NOPASSWD:ALL/g' /etc/sudoers \
    # To emulate the workspace-session behavior within dazzle build env
    && mkdir /workspace && chown -hR gitpod:gitpod /workspace

ENV HOME=/home/gitpod
WORKDIR $HOME 
RUN { echo && echo "PS1='\[\033[01;32m\]\u\[\033[00m\] \[\033[01;34m\]\w\[\033[00m\]\$(__git_ps1 \" (%s)\") $ '" ; } >> .bashrc

# Configure git-lfs
RUN git lfs install --system --skip-repo

### Gitpod user (2) ###
USER gitpod
RUN sudo echo "Running 'sudo' for Gitpod: success" && \
    # create .bashrc.d folder and source it in the bashrc
    mkdir -p /home/gitpod/.bashrc.d && \
    (echo; echo "for i in \$(ls -A \$HOME/.bashrc.d/); do source \$HOME/.bashrc.d/\$i; done"; echo) >> /home/gitpod/.bashrc && \
    # create a completions dir for gitpod user
    mkdir -p /home/gitpod/.local/share/bash-completion/completions

# Install some Python modules and poetry
RUN pip install --no-cache-dir --upgrade \
	setuptools wheel virtualenv pipenv pylint rope flake8 \
	mypy autopep8 pep8 pylama pydocstyle bandit notebook \
	twine && curl -sSL https://install.python-poetry.org | python
RUN sudo rm -rf /tmp/*

# Install Homebrew
RUN /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
ENV PATH=/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin/:$PATH
ENV MANPATH="$MANPATH:/home/linuxbrew/.linuxbrew/share/man"
ENV INFOPATH="$INFOPATH:/home/linuxbrew/.linuxbrew/share/info"
ENV HOMEBREW_NO_AUTO_UPDATE=1

# Configure Docker
RUN curl -o /usr/bin/slirp4netns -fsSL https://github.com/rootless-containers/slirp4netns/releases/download/v1.1.12/slirp4netns-x86_64 \
    && chmod +x /usr/bin/slirp4netns

RUN curl -o /usr/local/bin/docker-compose -fsSL https://github.com/docker/compose/releases/download/v2.4.1/docker-compose-linux-x86_64 \
    && chmod +x /usr/local/bin/docker-compose && mkdir -p /usr/local/lib/docker/cli-plugins && \
    ln -s /usr/local/bin/docker-compose /usr/local/lib/docker/cli-plugins/docker-compose

RUN curl -o /tmp/dive.tar.gz -fsSL https://github.com/wagoodman/dive/releases/download/v0.10.0/dive_0.10.0_linux_amd64.tar.gz \
    && tar -xf dive_0.10.0_linux_amd64.tar.gz && cp dive /usr/bin \
    && rm -rf /tmp/* dive

# Install Rust and Cargo
ENV PATH=$HOME/.cargo/bin:$PATH

RUN curl -fsSL https://sh.rustup.rs | sh -s -- -y --profile minimal --no-modify-path --default-toolchain stable \
        -c rls rust-analysis rust-src rustfmt clippy \
    && for cmp in rustup cargo; do rustup completions bash "$cmp" > "$HOME/.local/share/bash-completion/completions/$cmp"; done \
    && printf '%s\n'    'export CARGO_HOME=/workspace/.cargo' \
                        'mkdir -m 0755 -p "$CARGO_HOME/bin" 2>/dev/null' \
                        'export PATH=$CARGO_HOME/bin:$PATH' \
                        'test ! -e "$CARGO_HOME/bin/rustup" && mv "$(command -v rustup)" "$CARGO_HOME/bin"' > $HOME/.bashrc.d/80-rust \
    && cargo install cargo-watch cargo-edit cargo-workspaces \
    && rm -rf "$HOME/.cargo/registry" # This registry cache is now useless as we change the CARGO_HOME path to `/workspace`

RUN gem install bundler --no-document \
        && gem install solargraph --no-document

# Configure Apache and Nginx
RUN mkdir -p /var/run/nginx \
    && ln -s /etc/apache2/mods-available/rewrite.load /etc/apache2/mods-enabled/rewrite.load \
    && chown -R gitpod:gitpod /etc/apache2 /var/run/apache2 /var/lock/apache2 /var/log/apache2 \
    && chown -R gitpod:gitpod /etc/nginx /var/run/nginx /var/lib/nginx/ /var/log/nginx/
COPY --chown=gitpod:gitpod webserver/apache2/ /etc/apache2/
COPY --chown=gitpod:gitpod webserver/nginx /etc/nginx/
ENV APACHE_DOCROOT_IN_REPO="public"
ENV NGINX_DOCROOT_IN_REPO="public"

# Custom PATH additions
ENV PATH=$HOME/.local/bin:/usr/games/:$PATH