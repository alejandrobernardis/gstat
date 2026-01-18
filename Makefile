#!/usr/bin/env make
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.SILENT:

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

PROJECT_NAME=gstat

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

PWD:=$(CURDIR)
UID=$(shell id -u)
GID=$(shell id -g)

# package
PACKAGE_VERSION=$(shell command -p cat $(PWD)/VERSION 2>/dev/null)
PACKAGE_RELEASE=$(shell command -p cat $(PWD)/RELEASE 2>/dev/null)

# container
PKG_TOOLS=1
NET_TOOLS=1
SSH_PATH:=${HOME}/.ssh

# environment
ENV_FILE:=$(PWD)/example.env
ifneq ("$(wildcard $(PWD)/.env)","")
	ENV_FILE:=$(PWD)/.env
endif
ifneq ("$(wildcard $(ENV_FILE))","")
	include $(ENV_FILE)
	export sed 's/=.*//' $(ENV_FILE)
endif

# package
PACKAGE:=$(PWD)/package
PACKAGE_NAME=gstat
PACKAGE_SRC:=$(PWD)/src
ZSH_VERSION=$(shell command -p zsh --version 2>/dev/null | cut -d' ' -f2)
GIT_VERSION=$(shell command -p git --version 2>/dev/null | cut -d' ' -f3)

# container
WORKDIR=/home/frank
IMAGE:=$(PROJECT_NAME):dev
IMAGE_INSTALLER:=$(PROJECT_NAME):installer
CONTAINER:=$(PROJECT_NAME)

# distro
distro?=fedora
ifeq ("$(distro)","fedora")
	OS?=fedora:latest
endif
ifeq ("$(distro)","arch")
	OS?=archlinux:base
endif

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
_PRX=\033[38;5;
_RST=\033[m

help:
	command -p grep -E '^(##.*)|([a-zA-Z%\._-]+:.*?##\s.*)$$' $(PWD)/Makefile \
	  | awk 'BEGIN {FS = ":.*?## "} \
	    /^##@/ {printf "\n$(_RST)$(_PRX)123m%s\n", toupper(substr($$0, 4))} \
	    /^##~/ {printf "$(_RST)$(_PRX)159m%s\n",   substr($$0, 3)} \
	    /^##:/ {printf "$(_RST)$(_PRX)195m%s\n",   substr($$0, 4)} \
	    /^##-/ {printf "$(_RST)$(_PRX)237m%s\n",   substr($$0, 3)} \
	    /^##,/ {split(substr($$0, 5),x,"="); printf "$(_RST)$(_PRX)240;3m  - %-10s : %s\n", x[1], x[2]} \
	    /^[a-zA-Z].*/ {printf "$(_RST)$(_PRX)230m %-12s $(_PRX)250m-- %s\n", $$1, $$2 }' 1>&2
	printf 1>&2 '\n$(_RST)'

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

_cmd_sudo?=
ifneq ("$(shell id -u 2>/dev/null)","0")
	_cmd_sudo=sudo
endif

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

_cmd_oci=$(shell command -p -v docker 2>/dev/null)
_arg_oci?=
ifneq ("$(shell command -v podman 2>/dev/null)","")
	_cmd_oci=$(shell command -p -v podman 2>/dev/null)
	_arg_oci:=\
		--user $(UID):$(GID) \
		--userns keep-id
endif

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

nocache?=false

_arg_no_cache?=
ifeq ("$(nocache)","true")
	_arg_no_cache=\
		--no-cache
endif

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

proxy?=
noproxy?=localhost,127.0.0.1,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16

_arg_prx?=
ifneq ("$(proxy)","")
	_arg_prx:=\
		--build-arg HTTP_PROXY=$(proxy) \
		--build-arg HTTPS_PROXY=$(proxy) \
		--build-arg NO_PROXY=$(noproxy) \
		--build-arg http_proxy=$(proxy) \
		--build-arg https_proxy=$(proxy) \
		--build-arg no_proxy=$(noproxy)
endif

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

dns?=

_arg_dns?=
ifneq ("$(dns)","")
	_arg_dns:=\
		--dns $(dns)
endif

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

persist?=false

_arg_persist?=
ifeq ("$(persist)","true")
	_arg_persist=\
		--rm
endif

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

_cmd_dev:=\
	$(_cmd_oci) build \
		--progress plain \
		$(_arg_no_cache) \
		$(_arg_prx) \
		--build-arg OS=$(OS) \
		--build-arg PKG_TOOLS=$(PKG_TOOLS) \
		--build-arg NET_TOOLS=$(NET_TOOLS) \
		--file $(PWD)/.container/$(distro)_x86_64.Dockerfile

_cmd_run:=\
	$(_cmd_oci) run $(_arg_persist) --tty --interactive \
		--name $(CONTAINER) \
		$(_arg_dns) \
		$(_arg_oci) \
		--workdir $(WORKDIR)/$(PROJECT_NAME) \
		--env GH_ACCESS_TOKEN=${GH_ACCESS_TOKEN} \
		--volume $(PWD):$(WORKDIR)/$(PROJECT_NAME):z,delegated

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

_arg_vol:=\
	--volume ${HOME}/Development/repos:$(WORKDIR)/repos:z,ro

_arg_vol_ssh:=\
	--volume $(SSH_PATH):$(WORKDIR)/.ssh:ro

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

args?=

##@ Development
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
image:  ## Creates the container image.
	$(_cmd_dev) --target image --tag $(IMAGE) $(PWD)
##, distro=Linux Distribution (fedora, opts: arch)
##, nocache=Ignore container build cache (false, opts: true)
##, proxy=Proxy endpoint <protocol://host-or-ip:port> (empty)
##, noproxy=Proxy exceptions <host-or-ip> (localhost,127.0.0.1,...)
image.create: image create
# -----------------------------------------------------------------------------
.PHONY: image
##-----------------------------------------------------------------------------
create: destroy  ## Creates the container.
	$(_cmd_run) $(_arg_vol) $(IMAGE) $(args)
##, persist=Remove container after exit (false, opts: true)
##, dns=DNS server <host-or-ip> (empty)
create.ssh: destroy
	$(_cmd_run) $(_arg_vol) $(_arg_vol_ssh) $(IMAGE) $(args)
destroy:
	-$(_cmd_oci) remove --force $(CONTAINER) &>/dev/null && sleep 1
shell:  ## Access to container.
	$(_cmd_oci) exec --tty --interactive $(CONTAINER) tmux
kill:
	-$(_cmd_oci) kill $(CONTAINER) &>/dev/null && sleep 1
start:
	-$(_cmd_oci) start $(CONTAINER) &>/dev/null
restart: kill start
# -----------------------------------------------------------------------------
.PHONY: create destroy shell kill start restart
##-----------------------------------------------------------------------------


##@ Installation
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##: ⚠ By default is installed in `~/.local` or can set `prefix` to the desired
##:   path (i.e.): sudo make install prefix=/usr/local
##-----------------------------------------------------------------------------
prefix?=${HOME}/.local
# -----------------------------------------------------------------------------
i: install
install: uninstall man  ## Install components (alias: `i`).
	install -v -m 755 -d $(prefix)/etc/$(PACKAGE_NAME)
	install -v -m 755 -d $(prefix)/bin
	install -v -m 755 -d $(prefix)/lib/$(PACKAGE_NAME)
	install -v -m 755 -d $(prefix)/share/doc/$(PACKAGE_NAME)
	install -v -m 755 -d $(prefix)/share/man/man1
	install -v -m 755 -d $(prefix)/share/zsh/site-functions
	install -v -m 644 \
		$(PACKAGE_SRC)/etc/$(PACKAGE_NAME)/$(PACKAGE_NAME).conf \
		$(prefix)/etc/$(PACKAGE_NAME)/
	install -v -m 755 \
		$(PACKAGE_SRC)/usr/bin/$(PACKAGE_NAME) \
		$(prefix)/bin/
	install -v -m 755 \
		$(PACKAGE_SRC)/usr/lib/$(PACKAGE_NAME)/$(PACKAGE_NAME).zsh \
		$(prefix)/lib/$(PACKAGE_NAME)/
	# -
	sed -i -e "s|@VERSION@|$(PACKAGE_VERSION)|g" \
	           $(prefix)/lib/$(PACKAGE_NAME)/$(PACKAGE_NAME).zsh
	zsh -c 'zcompile $(prefix)/lib/$(PACKAGE_NAME)/$(PACKAGE_NAME).zsh'
	chmod 755 $(prefix)/lib/$(PACKAGE_NAME)/*.zwc
	# -
	install -v -m 644 \
		$(PACKAGE_SRC)/usr/share/doc/$(PACKAGE_NAME)/$(PACKAGE_NAME).1.md \
		$(prefix)/share/doc/$(PACKAGE_NAME)/
	# -
	install -v -m 644 \
		$(PACKAGE_SRC)/usr/share/zsh/site-functions/_$(PACKAGE_NAME) \
		$(prefix)/share/zsh/site-functions/
##, prefix=Installation path (${HOME}/.local)
u: uninstall
uninstall:  ## Uninstall components (alias: `u`).
	rm -vfr $(prefix)/etc/$(PACKAGE_NAME) \
		      $(prefix)/lib/$(PACKAGE_NAME) \
		      $(prefix)/share/doc/$(PACKAGE_NAME)
	rm -vf  $(prefix)/bin/$(PACKAGE_NAME) \
		      $(prefix)/share/man/man1/$(PACKAGE_NAME).1.gz \
		      $(prefix)/share/zsh/site-functions/_$(PACKAGE_NAME) \
##, prefix=Installation path (${HOME}/.local)
# -----------------------------------------------------------------------------
.PHONY: i install u uninstall
##-----------------------------------------------------------------------------
test:
	bash $(PWD)/scripts/test.sh
# -----------------------------------------------------------------------------
.PHONY: test
# -----------------------------------------------------------------------------


##@ Distribution
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##: ⚠ The RPM and PKG targets was designed to run into a container, please
##:   be careful.
##-----------------------------------------------------------------------------
RPM_PACKAGE:=$(PACKAGE_NAME)-$(PACKAGE_VERSION)
RPM_BUILD:=$(PWD)/rpmbuild
RPM_SOURCES:=$(RPM_BUILD)/SOURCES/$(RPM_PACKAGE).tar.gz
RPM_SPEC:=$(RPM_BUILD)/SPECS/$(PACKAGE_NAME).spec
RPM_TMP:=/tmp/$(RPM_PACKAGE)
# -----------------------------------------------------------------------------
rpm: man rpm.clean rpm.pre rpm.build  ## Create the RPM package
rpm.clean:
	rm -fr $(RPM_BUILD) $(RPM_TMP) ${HOME}/rpmbuild | true
rpm.pre:
	if mkdir -p $(RPM_BUILD)/{BUILD,RPMS,SOURCES,SPECS,SRPMS}; then \
		ln -frs $(RPM_BUILD) $(WORKDIR); \
		sed -e "s|@PACKAGE_VERSION@|$(PACKAGE_VERSION)|g" \
		    -e "s|@PACKAGE_RELEASE@|$(PACKAGE_RELEASE)|g" \
		    $(PACKAGE)/$(PACKAGE_NAME).spec >$(RPM_SPEC); \
		if mkdir -p $(RPM_TMP); then \
			cp -r $(PACKAGE_SRC)/* $(PWD)/LICENSE $(PWD)/VERSION \
				$(PWD)/RELEASE $(RPM_TMP)/; \
			tar --exclude='.gitkeep' --directory=/tmp -cvzf $(RPM_SOURCES) \
				$(RPM_PACKAGE); \
			sha256sum $(RPM_SOURCES) 2>/dev/null | cut -d' ' -f1 \
				>$(RPM_SOURCES).sha256; \
		fi; \
	fi
rpm.build:
	if rpmlint $(RPM_SPEC) &>/dev/null; then \
		rpmbuild --quiet -bb $(RPM_SPEC); \
	fi
# -----------------------------------------------------------------------------
rpm.i: rpm rpm.install
rpm.install:
	$(_cmd_sudo) rpm -vUh --reinstall $(RPM_BUILD)/RPMS/x86_64/*.rpm
rpm.u: rpm.uninstall
rpm.uninstall:
	if rpm -q $(PACKAGE_NAME) &>/dev/null; then \
		$(_cmd_sudo) rpm -ve $(PACKAGE_NAME); \
	fi
# -----------------------------------------------------------------------------
.PHONY: rpm
# -----------------------------------------------------------------------------
PKG_PACKAGE:=$(PACKAGE_NAME)-$(PACKAGE_VERSION)
PKG_BUILD:=$(PWD)/pkgbuild
PKG_SOURCES:=$(PKG_BUILD)/$(PKG_PACKAGE).tar.gz
PKG_SPEC:=$(PKG_BUILD)/PKGBUILD
PKG_TMP:=/tmp/$(PKG_PACKAGE)
# -----------------------------------------------------------------------------
pkg: man pkg.clean pkg.pre pkg.build  ## Create the PKG package
pkg.clean:
	rm -fr $(PKG_BUILD) $(PKG_TMP)
pkg.pre:
	if mkdir -p $(PKG_BUILD); then \
		sed -e "s|@PACKAGE_VERSION@|$(PACKAGE_VERSION)|g" \
		    -e "s|@PACKAGE_RELEASE@|$(PACKAGE_RELEASE)|g" \
		    $(PACKAGE)/PKGBUILD >$(PKG_SPEC); \
		if mkdir -p $(PKG_TMP); then \
			cp -r $(PACKAGE_SRC)/* $(PWD)/LICENSE $(PWD)/VERSION \
				$(PWD)/RELEASE $(PKG_TMP)/; \
			tar --exclude='.gitkeep' --directory=/tmp -cvzf $(PKG_SOURCES) \
				$(PKG_PACKAGE); \
			sha256sum $(PKG_SOURCES) 2>/dev/null | cut -d' ' -f1 \
				>$(PKG_SOURCES).sha256; \
			sed -e "s|^source=.*|source=('file://$(PKG_SOURCES)')|g" \
		    	-e "s|^sha256sums=.*|sha256sums=('`<$(PKG_SOURCES).sha256`')|g" \
		    	-i $(PKG_SPEC); \
		fi; \
	fi
pkg.build:
	if cd $(PKG_BUILD); then \
		makepkg; \
	fi
# -----------------------------------------------------------------------------
pkg.i: pkg pkg.install
pkg.install:
	$(_cmd_sudo) pacman -U --noconfirm $(PKG_BUILD)/*.zst
pkg.u: pkg.uninstall
pkg.uninstall:
	if  pacman -Q $(PACKAGE_NAME) &>/dev/null; then \
		$(_cmd_sudo) pacman -Runs --noconfirm $(PACKAGE_NAME); \
	fi
# -----------------------------------------------------------------------------
.PHONY: pkg
##-----------------------------------------------------------------------------
man: src/usr/share/man/man1/gstat.1.gz ## Create the linux manual
man.check: man
	man -l src/usr/share/man/man1/gstat.1.gz
src/usr/share/man/man1/gstat.1: src/usr/share/doc/gstat/gstat.1.md
	pandoc $(PWD)/$< --standalone --to=man > $@
src/usr/share/man/man1/gstat.1.gz: src/usr/share/man/man1/gstat.1
	gzip --best --force $(PWD)/$<
# -----------------------------------------------------------------------------
.PHONY: man
##-----------------------------------------------------------------------------
