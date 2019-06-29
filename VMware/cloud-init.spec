%{!?python_sitelib: %global python_sitelib %(%{__python} -c "from distutils.sysconfig import get_python_lib; print get_python_lib()")}

%define use_systemd (0%{?fedora} && 0%{?fedora} >= 18) || (0%{?rhel} && 0%{?rhel} >= 7)

%if %{use_systemd}
%define init_system systemd
%else
%define init_system sysvinit
%endif

# See: http://www.zarb.org/~jasonc/macros.php
# Or: http://fedoraproject.org/wiki/Packaging:ScriptletSnippets
# Or: http://www.rpm.org/max-rpm/ch-rpm-inside.html

Name:           cloud-init
Version:        18.5
Release:        71%{?dist}
Summary:        Cloud instance init scripts

Group:          System Environment/Base
License:        Dual-licesed GPLv3 or Apache 2.0
URL:            http://launchpad.net/cloud-init

Source0:        cloud-init-18.5-71-g86674f01.tar.gz
BuildArch:      noarch
BuildRoot:      %{_tmppath}

%if "%{?el6}" == "1"
BuildRequires:  python-argparse
%endif
%if %{use_systemd}
Requires:           systemd
BuildRequires:      systemd
Requires:           systemd-units
BuildRequires:      systemd-units
%else
Requires:           initscripts >= 8.36
Requires(postun):   initscripts
Requires(post):     chkconfig
Requires(preun):    chkconfig
%endif

# These are runtime dependencies, but declared as BuildRequires so that
# - tests can be run here.
# - parts of cloud-init such (setup.py) use these dependencies.
BuildRequires:  python-configobj
BuildRequires:  python-oauthlib
BuildRequires:  python-six
BuildRequires:  PyYAML
BuildRequires:  python-jsonpatch
BuildRequires:  python-jinja2
BuildRequires:  python-jsonschema
BuildRequires:  python-requests
BuildRequires:  e2fsprogs
BuildRequires:  iproute
BuildRequires:  net-tools
BuildRequires:  procps
BuildRequires:  rsyslog
BuildRequires:  shadow-utils
BuildRequires:  sudo
BuildRequires:  python-devel
BuildRequires:  python-setuptools

# System util packages needed
%ifarch %{?ix86} x86_64 ia64
Requires:       dmidecode
%endif

# python2.6 needs argparse
%if "%{?el6}" == "1"
Requires:  python-argparse
%endif


# Install 'dynamic' runtime reqs from *requirements.txt and pkg-deps.json
Requires:       python-configobj
Requires:       python-oauthlib
Requires:       python-six
Requires:       PyYAML
Requires:       python-jsonpatch
Requires:       python-jinja2
Requires:       python-jsonschema
Requires:       python-requests
Requires:       e2fsprogs
Requires:       iproute
Requires:       net-tools
Requires:       procps
Requires:       rsyslog
Requires:       shadow-utils
Requires:       sudo
Requires:       python-devel
Requires:       python-setuptools

# Custom patches

%if "%{init_system}" == "systemd"
Requires(post):       systemd
Requires(preun):      systemd
Requires(postun):     systemd
%else
Requires(post):       chkconfig
Requires(postun):     initscripts
Requires(preun):      chkconfig
Requires(preun):      initscripts
%endif

%description
Cloud-init is a set of init scripts for cloud instances.  Cloud instances
need special scripts to run during initialization to retrieve and install
ssh keys and to let the user run various scripts.

%prep
%setup -q -n cloud-init-18.5-71-g86674f01

# Custom patches activation

%build
%{__python} setup.py build

%install

%{__python} setup.py install -O1 \
            --skip-build --root $RPM_BUILD_ROOT \
            --init-system=%{init_system}

# Note that /etc/rsyslog.d didn't exist by default until F15.
# el6 request: https://bugzilla.redhat.com/show_bug.cgi?id=740420
mkdir -p $RPM_BUILD_ROOT/%{_sysconfdir}/rsyslog.d
cp -p tools/21-cloudinit.conf \
      $RPM_BUILD_ROOT/%{_sysconfdir}/rsyslog.d/21-cloudinit.conf

# Remove the tests
rm -rf $RPM_BUILD_ROOT%{python_sitelib}/tests

# Required dirs...
mkdir -p $RPM_BUILD_ROOT/%{_sharedstatedir}/cloud
mkdir -p $RPM_BUILD_ROOT/%{_libexecdir}/%{name}

# patch in the full version to version.py
version_pys=$(cd "$RPM_BUILD_ROOT" && find . -name version.py -type f)
[ -n "$version_pys" ] ||
   { echo "failed to find 'version.py' to patch with version." 1>&2; exit 1; }
( cd "$RPM_BUILD_ROOT" &&
  sed -i "s,@@PACKAGED_VERSION@@,%{version}-%{release}," $version_pys )

%clean
rm -rf $RPM_BUILD_ROOT

%post

%if "%{init_system}" == "systemd"
if [ $1 -eq 1 ]
then
    /bin/systemctl enable cloud-config.service     >/dev/null 2>&1 || :
    /bin/systemctl enable cloud-final.service      >/dev/null 2>&1 || :
    /bin/systemctl enable cloud-init.service       >/dev/null 2>&1 || :
    /bin/systemctl enable cloud-init-local.service >/dev/null 2>&1 || :
fi
%else
/sbin/chkconfig --add %{_initrddir}/cloud-init-local
/sbin/chkconfig --add %{_initrddir}/cloud-init
/sbin/chkconfig --add %{_initrddir}/cloud-config
/sbin/chkconfig --add %{_initrddir}/cloud-final
%endif

%preun

%if "%{init_system}" == "systemd"
if [ $1 -eq 0 ]
then
    /bin/systemctl --no-reload disable cloud-config.service >/dev/null 2>&1 || :
    /bin/systemctl --no-reload disable cloud-final.service  >/dev/null 2>&1 || :
    /bin/systemctl --no-reload disable cloud-init.service   >/dev/null 2>&1 || :
    /bin/systemctl --no-reload disable cloud-init-local.service >/dev/null 2>&1 || :
fi
%else
if [ $1 -eq 0 ]
then
    /sbin/service cloud-init stop >/dev/null 2>&1 || :
    /sbin/chkconfig --del cloud-init || :
    /sbin/service cloud-init-local stop >/dev/null 2>&1 || :
    /sbin/chkconfig --del cloud-init-local || :
    /sbin/service cloud-config stop >/dev/null 2>&1 || :
    /sbin/chkconfig --del cloud-config || :
    /sbin/service cloud-final stop >/dev/null 2>&1 || :
    /sbin/chkconfig --del cloud-final || :
fi
%endif

%postun

%if "%{init_system}" == "systemd"
/bin/systemctl daemon-reload >/dev/null 2>&1 || :
%endif

%files

/lib/udev/rules.d/66-azure-ephemeral.rules

%if "%{init_system}" == "systemd"
/usr/lib/systemd/system-generators/cloud-init-generator
%{_unitdir}/cloud-*
%else
%attr(0755, root, root) %{_initddir}/cloud-config
%attr(0755, root, root) %{_initddir}/cloud-final
%attr(0755, root, root) %{_initddir}/cloud-init-local
%attr(0755, root, root) %{_initddir}/cloud-init
%endif

%{_sysconfdir}/NetworkManager/dispatcher.d/hook-network-manager
%{_sysconfdir}/dhcp/dhclient-exit-hooks.d/hook-dhclient

# Program binaries
%{_bindir}/cloud-init*
%{_bindir}/cloud-id*

# Docs
%doc LICENSE ChangeLog TODO.rst requirements.txt
%doc %{_defaultdocdir}/cloud-init/*

# Configs
%config(noreplace)      %{_sysconfdir}/cloud/cloud.cfg
%dir                    %{_sysconfdir}/cloud/cloud.cfg.d
%config(noreplace)      %{_sysconfdir}/cloud/cloud.cfg.d/*.cfg
%config(noreplace)      %{_sysconfdir}/cloud/cloud.cfg.d/README
%dir                    %{_sysconfdir}/cloud/templates
%config(noreplace)      %{_sysconfdir}/cloud/templates/*
%config(noreplace) %{_sysconfdir}/rsyslog.d/21-cloudinit.conf

# Bash completion script
%{_datadir}/bash-completion/completions/cloud-init

%{_libexecdir}/%{name}
%dir %{_sharedstatedir}/cloud

# Python code is here...
%{python_sitelib}/*