#!jinja|yaml
# vi: set ft=yaml.jinja :

{%- from "kodi/map.jinja" import datamap with context %}
{% set svc_state      = salt['pillar.get']('kodi:lightdm:svc_state', 'running') -%}
{% set svc_onboot     = salt['pillar.get']('kodi:lightdm:svc_onboot', True) -%}

include:
  - avahi

kodi_repo:
  pkgrepo.managed:
    - humanname: team-xbmc-ppa-{{ grains['oscodename'] }}
    - name: deb http://ppa.launchpad.net/team-xbmc/ppa/ubuntu/ {{ grains['oscodename'] }} main
    - file: /etc/apt/sources.list.d/team-xbmc-ppa-{{ grains['oscodename'] }}.list
    - dist: {{ grains['oscodename'] }}
    - keyid: 91E7EE5E
    - keyserver: keyserver.ubuntu.com
    - refresh: True

{%- if salt['pillar.get']('kodi:lightdm:install', True) %}
kodi_lightdm:
  pkg.installed:
    - pkgs: {{ datamap.lightdm.pkgs }}
  file.managed:
    - name: {{ datamap.lightdm.conf_file }}
    - source: {{ datamap.lightdm.conf_template }}
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: kodi_lightdm
    - require_in:
      - pkg: kodi
  service.{{ svc_state }}:
    - name: {{ datamap.lightdm.svc_name }}
    - enable: {{ svc_onboot }}
    - require:
      - file: kodi_lightdm
    - watch:
      - file: kodi_lightdm

kodi_lightdm_default:
  file.managed:
    - name: /etc/X11/default-display-manager
    - contents: |
        /usr/sbin/lightdm
    - user: root
    - group: root
    - mode: 644
    - watch:
      - pkg: kodi_lightdm
{% endif %}

kodi:
  pkg.installed:
    - pkgs: {{ datamap.kodi_pkgs }}
    - require:
      - sls: avahi
      - pkgrepo: kodi_repo
