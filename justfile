#!/usr/bin/env just --justfile

default:
  @just --list

unit_test:
  @nodemon --exec 'echo -en "\n\n\n\n------------- BUSTED -------------\n"; busted spec' -e 'lua'

test TAG:
  @busted spec --tags {{TAG}}

tests:
  @busted spec

lint FILE='':
  @stylua --column-width 65 {{FILE}}
