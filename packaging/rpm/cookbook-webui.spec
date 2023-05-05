Name: cookbook-webui
Version: %{__version}
Release: %{__release}%{?dist}
BuildArch: noarch
Requires: wkhtmltox
Summary: WebUI cookbook to install and configure it in redborder environments

License: AGPL 3.0
URL: https://github.com/redBorder/cookbook-webui
Source0: %{name}-%{version}.tar.gz

%description
%{summary}

%prep
%setup -qn %{name}-%{version}

%build

%install
mkdir -p %{buildroot}/var/chef/cookbooks/webui
cp -f -r  resources/* %{buildroot}/var/chef/cookbooks/webui
chmod -R 0755 %{buildroot}/var/chef/cookbooks/webui
install -D -m 0644 README.md %{buildroot}/var/chef/cookbooks/webui/README.md

%pre

%post
case "$1" in
  1)
    # This is an initial install.
    :
  ;;
  2)
    # This is an upgrade.
    su - -s /bin/bash -c 'source /etc/profile && rvm gemset use default && env knife cookbook upload webui'
  ;;
esac

%files
%defattr(0755,root,root)
/var/chef/cookbooks/webui
%defattr(0644,root,root)
/var/chef/cookbooks/webui/README.md


%doc

%changelog
* Fri May 05 2023 Luis J. Blanco Mier <ljblanco@redborder.com> - 0.1.2
- default dashboard
* Fri Jan 07 2022 David Vanhoucke <dvanhoucke@redborder.com> - 0.0.10-1
- change register to consul
* Tue Nov 08 2016 Your name <cjmateos@redborder.com> - 1.0.0-1
- first spec version
