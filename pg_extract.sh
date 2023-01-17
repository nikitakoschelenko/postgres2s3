#!/bin/bash
# https://stackoverflow.com/a/48866503

[ $# -lt 2 ] && { echo "Usage: $0 <postgresql dump> <dbname>"; exit 1; }

sed  "/connect.*$2/,\$!d" $1 | sed "/PostgreSQL database dump complete/,\$d"
