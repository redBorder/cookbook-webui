cookbook-webui CHANGELOG
===============

## 1.6.1

  - Rafael Gomez
    - [6998822] Add s3_secrets attribute to config resource

## 1.6.0

  - Miguel Negrón
    - [7af79d3] Merge pull request #93 from redBorder/bugfix/#22031_add_missing_cdomain_to_chef_config
  - Rafael Gomez
    - [f2c4bb4] Add missing cdomain to chef_config.yml.erb

## 1.5.2

  - nilsver
    - [c255561] remove flush cache

## 1.5.1

  - nilsver
    - [28be65f] permission issue fix
    - [20cf1e3] make name more indicative for task

## 1.5.0

  - Rafa Gómez
    - [d9897b8] Add custom error page handling for 504 errors in webui configuration (#87)

## 1.4.2

  - Rafael Gomez
    - [24a05de] Add log rotation for webui logs and remove file size check

## 1.4.1

  - Rafael Gomez
    - [833e644] Reduce druid_query_logging_file_path size limit from 50 MB to 10 MB
    - [6de3ed1] Update druid_query_logging_file_path to use .log extension and remove file creation block

## 1.4.0

  - Rafael Gomez
    - [8cb661f] Refactor clean_stale_delayed_jobs rake task execution in config.rb to use execute_rake_task method
  - nilsver
    - [bc0a257] check for stale jobs every chef run

## 1.3.1

  - Rafael Gomez
    - [487e2d1] Update database migration and asset management commands to use 'bundle exec', 'source' and 'export'

## 1.3.0

  - Rafael Gomez
    - [186c973] Add druid query logging file size check and cleanup

## 1.2.2

  - Pablo Pérez
    - [c51e9e7] Added sso_sensor_map.yml

## 1.2.1

  - Miguel Alvarez
    - [c4a94ae] Add autoforward in nginx

## 1.2.0

  - Pablo Pérez
    - [1929715] Rename redborder-ai to redborder-llm

## 1.1.1

  - Miguel Alvarez
    - [3c0c83f] Fix assets

## 1.1.0

  - manegron
    - [ecf9bd7] Add version

## 1.0.0

  - Miguel Negrón
    - [74e9b01] Merge pull request #63 from redBorder/improvement/boost_installation_stage_1
    - [c8fc762] Merge pull request #60 from redBorder/development
    - [2701d25] Merge pull request #45 from redBorder/feature/#18077_addPuppeteerGrover
    - [6c2ddac] Merge pull request #59 from redBorder/development
    - [3a1d1c5] Merge pull request #58 from redBorder/development
    - [cce4c28] Merge pull request #57 from redBorder/bugfix/#18648_dont_use_point_node_in_nginx
    - [74e9b01] Merge pull request #63 from redBorder/improvement/boost_installation_stage_1
    - [76968fc] Fix lint
    - [d2c5a5c] Not notify restart if leader still in configuring
    - [ba072c2] Adapt leader configuring
    - [c8cadd6] Add support to stop
    - [b723c97] Add support to stop
    - [88e230b] remove configure_db and configure_server_key_trial_license
    - [05c0b45] remove configure_db and configure_server_key_trial_license
    - [b2907d2] Testing
    - [696af1b] Testing
    - [64ca979] Testing
    - [f76c802] Testing
    - [efb1b54] Fix typo
    - [2e39842] Fix typo
    - [64dc8e6] Change webui init
    - [8ec1a8a] Add configure_server_key_trial_license
    - [4379c74] Bump version
    - [8481910] Add pre and postun to clean the cookbook
    - [c8fc762] Merge pull request #60 from redBorder/development
    - [442939d] Bump version
    - [2701d25] Merge pull request #45 from redBorder/feature/#18077_addPuppeteerGrover
    - [59ad767] Rename puppeteer RPM to redborder-webui-node-modules
    - [493e0c1] resolve conflicts with development
    - [6c2ddac] Merge pull request #59 from redBorder/development
    - [1f1c52f] Update provider to pass lint
    - [ac74500] Bump version
    - [6ab4784] Add new way to trigger webui upgrade steps
    - [3a1d1c5] Merge pull request #58 from redBorder/development
    - [fd31222] Bump version & CHANGELOG
    - [cce4c28] Merge pull request #57 from redBorder/bugfix/#18648_dont_use_point_node_in_nginx
    - [e01cb56] dont use .node in nginx
  - Rafael Gomez
    - [4588098] Release 0.4.1
  - Rafa Gómez
    - [4e52599] Merge pull request #61 from redBorder/bugfix/18751_fix_webui_ownership
  - Daniel Castro
    - [eab76b2] Change rb-rails ownership to webui after assets:precompile
    - [8779206] Increase version to 0.2.5
    - [4b04076] Add puppeteer-rpm and redborder-nodenvm
  - Miguel Negron
    - [442939d] Bump version
    - [59ad767] Rename puppeteer RPM to redborder-webui-node-modules
    - [493e0c1] resolve conflicts with development
    - [1f1c52f] Update provider to pass lint
    - [ac74500] Bump version
    - [6ab4784] Add new way to trigger webui upgrade steps
    - [fd31222] Bump version & CHANGELOG
    - [e01cb56] dont use .node in nginx

## 0.4.2

  - Miguel Negrón
    - [8481910] Add pre and postun to clean the cookbook

## 0.4.1

  - Daniel Castro
    - [eab76b2] Change rb-rails ownership to webui after assets:precompile

## 0.4.0

  - Miguel Negrón
    - [2701d25] Merge pull request #45 from redBorder/feature/#18077_addPuppeteerGrover
    - [cce4c28] Merge pull request #57 from redBorder/bugfix/#18648_dont_use_point_node_in_nginx
  - Miguel Negrón
    - [59ad767] Rename puppeteer RPM to redborder-webui-node-modules
    - [493e0c1] resolve conflicts with development
    - [1f1c52f] Update provider to pass lint
    - [ac74500] Bump version
    - [6ab4784] Add new way to trigger webui upgrade steps
    - [fd31222] Bump version & CHANGELOG
    - [e01cb56] dont use .node in nginx
  - Daniel Castro
    - [8779206] Increase version to 0.2.5
    - [4b04076] Add puppeteer-rpm and redborder-nodenvm

## 0.3.7

  - Miguel Negrón
    - [6ab4784] Add new way to trigger webui upgrade steps
    - [fd31222] Bump version & CHANGELOG
    - [e01cb56] dont use .node in nginx
  - Miguel Negrón
    - [cce4c28] Merge pull request #57 from redBorder/bugfix/#18648_dont_use_point_node_in_nginx

## 0.3.6

  - Miguel Negrón
    - [cce4c28] Merge pull request #57 from redBorder/bugfix/#18648_dont_use_point_node_in_nginx
  - Miguel Negrón
    - [e01cb56] dont use .node in nginx

## 0.3.5

  - Miguel Negrón
    - [24d586f] Merge pull request #55 from redBorder/feature/#18514_add_upload_external_cert

## 0.3.4

  - Miguel Negrón
    - [c30c503] fix bug

## 0.3.3

  - Miguel Negrón
    - [c7971ff] Add and improve delete code by accident

## 0.3.2

  - Miguel Negrón
    - [b65125f] Merge pull request #51 from redBorder/bugfix/#1842_remove_newrelic

## 0.3.1

  - Miguel Negrón
    - [2d3ce75] Merge pull request #50 from redBorder/bugfix/#18253_newrelic.yml

## 0.3.0

  - Pablo Pérez
    - [c2fd5a6] Added the saml certificate
  - nilsver
    - [879db7a] Fix rsa key missing in nodes

## 0.2.5

  - Miguel Negrón
    - [88ef1a8] Merge pull request #44 from redBorder/feature/#18106_install_llamafile_as_service_wth_improve_download_models

## 0.2.4

  - JuanSheba
    - [654414b] Fix lint
    - [6db877f] Set hostname as memcached_server default value

## 0.2.3

  - Miguel Negrón
    - [8c95c91] clean assets before precompile on updates

## 0.2.2

  - Miguel Negrón
    - [6293c0c] Dont run seed everytime

## 0.2.1

  - Miguel Alvarez
    - [c548465] Random 128 bit serial

## 0.2.0

  - Pablo Pérez
    - [15fc1b9] Rename of variable
    - [7c11cdb] Adapt to support SSO

## 0.1.15

  - Miguel Negrón
    - [28ce81e] Run assets precompile as root

## 0.1.14

  - Miguel Negrón
    - [5fede59] Merge pull request #36 from redBorder/bugfix/#18058_fix_call_migrate_dittoc_assets_on_updates

## 0.1.13

  - Miguel Alvarez
    - [4edc69c] Add memcached servers to webui

## 0.1.12

  - Miguel Negrón
    - [f530cb2] Remove bi module

## 0.1.11

  - Miguel Álvarez
    - [1ef00f6] Update config.rb
    - [0cb51ba] Merge branch 'development' into bugfix/17690_loadbalancer_webui
    - [2690f6e] Fix lints
    - [a794aac] Configure nginx load balancer with all nodes

## 0.1.10

  - Miguel Negrón
    - [02252f6] lint

This file is used to list changes made in each version of the redborder webui cookbook.

0.0.1
-----
- [your_name]
  - COMMIT_REF Initial release of cookbook example

- - -
Check the [Markdown Syntax Guide](http://daringfireball.net/projects/markdown/syntax) for help with Markdown.

The [Github Flavored Markdown page](http://github.github.com/github-flavored-markdown/) describes the differences between markdown on github and standard markdown.
