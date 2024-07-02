Name:           gstat
Version:        @PACKAGE_VERSION@
Release:        @PACKAGE_RELEASE@
Summary:        Show summary changes for multiple git repositories

License:        MIT
URL:            https://github.com/alejandrobernardis/gstat
Source0:        %{name}-%{version}.tar.gz

BuildRequires: sed
BuildRequires: zsh
Requires: bash >= 4.0
Requires: zsh  >= 5.0
Requires: git  >= 2.0

%description

gstat(1) was created to solve the daily dynamics of finding outstanding
issues in local repositories, many of the expected statuses will not be
resolved.


The current statuses are:

- Push: if a branch is following a (remote) branch behind it.
- Pull: if a branch is following a (remote) branch ahead it.
- Upstream: if a branch does not have a local or remote upstream branch
configured.
- Uncommitted: if there are uncommitted changes pending in the local
repository.
- Staged: if there are staged changes in the local repository.
- Stashes: if there are saved changes in the local repository.
- Untracked: if there are untracked files that are not ignored in the
local repository.
- Conflicts: if there are conflicts pending in the current branch.

If you run in check mode (-c) it will show you all repositories
that are Ignored (gstat.ignore=true), Locked (.git/index.lock)
or Insecure (non-owner).


Alternative paths to the configuration file:

- ${HOME}/.gstat.conf
- ${HOME}/.config/gstat/gstat.conf
- ${HOME}/.local/etc/gstat.conf
- /usr/local/etc/gstat/gstat.conf
- /usr/etc/gstat/gstat.conf
- /etc/gstat/gstat.conf

--

%prep
%setup -q

%install
rm -rf %{buildroot}/*
install -d -m 0755 %{buildroot}/etc/%{name}
install -m 0644 etc/%{name}/%{name}.conf %{buildroot}/etc/%{name}/%{name}.conf
install -d -m 0755 %{buildroot}/usr/bin
install -p -m 0755 usr/bin/%{name} %{buildroot}/usr/bin/%{name}
install -d -m 0755 %{buildroot}/usr/lib/%{name}
sed -e "s|@VERSION@|%{version}|g" -i usr/lib/%{name}/%{name}.zsh
zsh -c "zcompile usr/lib/%{name}/%{name}.zsh"
install -p -m 0644 usr/lib/%{name}/%{name}.zsh %{buildroot}/usr/lib/%{name}/%{name}.zsh
install -p -m 0644 usr/lib/%{name}/%{name}.zsh.zwc %{buildroot}/usr/lib/%{name}/%{name}.zsh.zwc
install -d -m 0755 %{buildroot}/usr/share/doc/%{name}
install -p -m 0644 VERSION %{buildroot}/usr/share/doc/%{name}/VERSION
install -p -m 0644 RELEASE %{buildroot}/usr/share/doc/%{name}/RELEASE
install -p -m 0644 usr/share/doc/%{name}/%{name}.1.md %{buildroot}/usr/share/doc/%{name}/%{name}.1.md
install -d -m 0755 %{buildroot}/usr/share/man/man1
install -p -m 0644 usr/share/man/man1/%{name}.1.gz %{buildroot}/usr/share/man/man1/%{name}.1.gz

%files
%defattr(-,root,root)
/etc/%{name}/%{name}.conf
/usr/bin/%{name}
/usr/lib/%{name}/%{name}.zsh
/usr/lib/%{name}/%{name}.zsh.zwc
/usr/share/doc/%{name}/VERSION
/usr/share/doc/%{name}/RELEASE
/usr/share/doc/%{name}/%{name}.1.md
/usr/share/man/man1/%{name}.1.gz
%license LICENSE

%changelog
* Sun Jul 07 2024 Alejandro M. BERNARDIS <alejandro.bernardis@gmail.com> - 1.0.0-1
- Initial version.
