FROM library/archlinux
RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm base-devel git git-lfs htop sudo nano vim man-db zsh fish ripgrep stow which emacs-nox multitail ruby openssh \
    lsof jq zip unzip meson docker clang lld rlwrap clojure go rustup cmake apache nginx php php-fpm php-gd php-pgsql php-sqlite python-pip nodejs npm \
     && locale-gen en_US.UTF-8 

### Gitpod user ###
COPY sudoers /etc
RUN useradd -l -u 33333 -G wheel -md /home/gitpod -s /bin/bash -p gitpod gitpod \
    # To emulate the workspace-session behavior within dazzle build env
    && mkdir /workspace && chown -hR gitpod:gitpod /workspace

ENV HOME=/home/gitpod
WORKDIR $HOME
# custom Bash prompt
COPY --chown=gitpod:gitpod bash.bashrc /home/gitpod/.bashrc

# configure git-lfs
RUN git lfs install --system --skip-repo

### Gitpod user (2) ###
USER gitpod
# use sudo so that user does not get sudo usage info on (the first) login
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

RUN gem install bundler --no-document \
        && gem install solargraph --no-document

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

# Configure Apache and Nginx
USER root
RUN mkdir -p /var/run/nginx
COPY --chown=gitpod:gitpod webserver/apache2/ /etc/apache2/
COPY --chown=gitpod:gitpod webserver/nginx/ /etc/nginx/
ENV APACHE_DOCROOT_IN_REPO="public"
ENV NGINX_DOCROOT_IN_REPO="public"
USER gitpod

# Custom PATH additions
ENV PATH=$HOME/.local/bin:$PATH