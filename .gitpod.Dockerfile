FROM library/archlinux
RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm base-devel git git-lfs htop sudo nano vim man-db zsh fish ripgrep stow which emacs-nox multitail ruby \
    lsof jq zip unzip meson docker clang lld rlwrap clojure go rustup cmake apache nginx php php-fpm php-gd php-pgsql php-sqlite python-pip nodejs npm\
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