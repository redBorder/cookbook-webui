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
if [ -d /var/chef/cookbooks/webui ]; then
    rm -rf /var/chef/cookbooks/webui
fi

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

%postun
# Deletes directory when uninstall the package
if [ "$1" = 0 ] && [ -d /var/chef/cookbooks/webui ]; then
  rm -rf /var/chef/cookbooks/webui
fi

%files
%defattr(0644,root,root)
%attr(0755,root,root)
/var/chef/cookbooks/webui
%defattr(0644,root,root)
/var/chef/cookbooks/webui/README.md


%doc

%changelog
* Thu Oct 10 2024 Miguel Negrón <manegron@redborder.com>
- Add pre and postun

* Thu Jan 18 2024 Miguel Negrón <manegron@redborder.com>
- Fix multidatasource and location druid datastore name

* Thu Nov 16 2023 Miguel Negrón <manegron@redborder.com>
- Add optional audits for webui

* Fri May 05 2023 Luis J. Blanco Mier <ljblanco@redborder.com>
- default dashboard

* Fri Jan 07 2022 David Vanhoucke <dvanhoucke@redborder.com>
- change register to consul

* Tue Nov 08 2016 Your name <cjmateos@redborder.com>
- first spec version
