Name: cookbook-webui
Version: %{__version}
Release: %{__release}%{?dist}
BuildArch: noarch
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
su - -s /bin/bash -c 'source /etc/profile && rvm gemset use default && ! env knife data bag show certs rsa_pem &>/dev/null && [ -f /usr/lib/redborder/bin/rb_create_rsa.sh ] && sudo /usr/lib/redborder/bin/rb_create_rsa.sh -f'
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
* Fri Jan 07 2022 David Vanhoucke <dvanhoucke@redborder.com> - 0.0.10-1
- change register to consul
* Tue Nov 08 2016 Your name <cjmateos@redborder.com> - 1.0.0-1
- first spec version
