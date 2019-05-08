Summary: Cloud image management utilities
Name: cloud-utils
Version: 0.31
Release: 1
License: GPLv3
Group: System/Configuration/Boot and Init
Url: https://launchpad.net/cloud-utils

# vcs git: https://git.launchpad.net/cloud-utils
Source: %name-%version.tar.gz

BuildArch: noarch

Requires: cloud-utils-growpart
Requires: gawk
Requires: e2fsprogs
Requires: euca2ools
Requires: file
Requires: util-linux
Requires: qemu-img
Requires: /usr/bin/qemu-img

%description
This package provides a useful set of utilities for managing cloud images.

The euca2ools package (a dependency of cloud-utils) provides an Amazon EC2 API
compatible set of utilities for bundling kernels, ramdisks, and root
filesystems, and uploading them to either EC2 or UEC.

The tasks associated with image bundling are often tedious and repetitive. The
cloud-utils package provides several scripts that wrap the complicated tasks
with a much simpler interface.

%package growpart
Summary: Script for growing a partition
Group: System/Configuration/Boot and Init

Requires: gawk
Requires: gdisk
Requires: sfdisk
Requires: util-linux

%description growpart
This package provides the growpart script for growing a partition. It is
primarily used in cloud images in conjunction with the dracut-modules-growroot
package to grow the root partition on first boot.

%prep
%setup

%build

%install
# Create the target directories
mkdir -p $RPM_BUILD_ROOT/%{_bindir}
mkdir -p $RPM_BUILD_ROOT/%{_mandir}/man1

# Install binaries and manpages
cp bin/* $RPM_BUILD_ROOT/%{_bindir}/
cp man/* $RPM_BUILD_ROOT/%{_mandir}/man1/

# Exclude Ubuntu-specific tools
rm $RPM_BUILD_ROOT/%{_bindir}/*ubuntu*

# Install the growpart binary and man page
cp bin/growpart $RPM_BUILD_ROOT/%{_bindir}/
cp man/growpart.* $RPM_BUILD_ROOT/%{_mandir}/man1/

# Exclude Ubuntu-specific tools
rm -f %buildroot%_bindir/*ubuntu*

%files
%doc ChangeLog
%_bindir/*
%_mandir/*
%exclude %_bindir/growpart
%exclude %_mandir/man1/growpart.*

%files growpart
%doc ChangeLog
%_bindir/growpart
%_mandir/man1/growpart.*

%changelog
* Thu Jan 17 2019 Alexey Shabalin <shaba@altlinux.org> 0.31-alt1
- 0.31

* Thu Sep 28 2017 Alexey Shabalin <shaba@altlinux.ru> 0.30-alt1%ubt
- 0.30

* Tue Nov 22 2016 Alexey Shabalin <shaba@altlinux.ru> 0.29-alt1.20161024
- bzr snapshot 20161024

* Thu Dec 03 2015 Alexey Shabalin <shaba@altlinux.ru> 0.27-alt1.20151203
- Initial build upstream snapshot