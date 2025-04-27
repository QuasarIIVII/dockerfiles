FROM ubuntu

RUN echo "debconf debconf/frontend select Noninteractive" | debconf-set-selections
RUN apt-get update
RUN apt-get install -y apt-utils

RUN TERM=/bin/bash apt-get install -y	\
	sudo								\
	curl								\
	wget								\
	aria2

RUN useradd -m -G sudo user
RUN passwd -d user

RUN echo "export SH_ANACONDA='$(curl -s "https://raw.githubusercontent.com/QuasarIIVII/dockerfiles/main/archive/anaconda.sh")'" > /tmp/env
RUN . /tmp/env && echo $SH_ANACONDA
RUN . /tmp/env \
	&& sudo -u user bash -c "$SH_ANACONDA" anaconda.sh install \
	&& : \
	&& TERM=/bin/bash apt-get install -y\
	build-essential cmake				\
	python3 python3-pip python3-venv	\
	git									\
	neovim								\
	zsh									\
	htop								\
	language-pack-en					\
	&& : \
	&& locale-gen en_US.UTF-8 \
	&& sudo -u user bash -c "$SH_ANACONDA" anaconda.sh wait

#	python3-dev

ENV RT_HOME=$HOME

RUN sh -c "$(wget -O- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
RUN sed -i.bac 's/^ZSH_THEME="robbyrussell"$/ZSH_THEME="agnoster"/' ~/.zshrc
RUN chsh -s /bin/zsh

RUN mkdir -p $RT_HOME/.config/nvim
RUN echo """\
language en_US.UTF-8\n\
\n\
set tabline=4\n\
set tabstop=4\n\
set shiftwidth=4\n\
set number\n\
set history=1024\n\
set incsearch\n\
set nocindent\n\
set smartindent\n\
set noexpandtab\n\
filetype indent off\n\
set ignorecase\n\
\n\
set pastetoggle=<F5>\n\
\n\
autocmd FileType python setlocal noexpandtab\n\
autocmd FileType python setlocal softtabstop=0\n\
""" > $RT_HOME/.config/nvim/init.vim
RUN mkdir -p $HOME/.config/nvim

ENV HOME="/home/user"

RUN sudo -u user sh -c "$(wget -O- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
RUN sed -i.bac 's/^ZSH_THEME="robbyrussell"$/ZSH_THEME="agnoster"/' $HOME/.zshrc
RUN chsh user -s /bin/zsh
RUN cp $RT_HOME/.config/nvim/init.vim $HOME/.config/nvim/init.vim

RUN . /tmp/env \
	&& SHELL=/bin/zsh sudo -u user bash -c "$SH_ANACONDA" anaconda.sh init

RUN rm /tmp/env

USER user
WORKDIR $HOME

CMD ["/bin/zsh"]
