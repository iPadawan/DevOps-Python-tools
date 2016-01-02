#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2015-12-22 23:39:33 +0000 (Tue, 22 Dec 2015)
#
#  https://github.com/harisekhon/pytools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help improve or steer this or other code I publish
#
#  http://www.linkedin.com/in/harisekhon
#

set -euo pipefail
srcdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "
# ======================== #
# Testing validate_xml.py
# ======================== #
"

cd "$srcdir/..";

. ./tests/utils.sh

until [ $# -lt 1 ]; do
    case $1 in
        -*) shift
    esac
done

data_dir="tests/data"
broken_dir="tests/broken_xml"

rm -fr "$broken_dir" || :
mkdir "$broken_dir"
./validate_xml.py -vvv $(
find "${1:-.}" -iname '*.xml' |
grep -v '/spark-.*-bin-hadoop.*/' |
grep -v -e 'broken' -e 'error' -e ' '
)
echo

echo
echo "checking directory recursion (mixed with explicit file given)"
./validate_xml.py -vvv "$data_dir/simple.xml" .
echo

echo "checking xml file without an extension"
cp -iv "$(find "${1:-.}" -iname '*.xml' | grep -v -e '/spark-.*-bin-hadoop.*/' -e 'broken' -e 'error' | head -n1)" "$broken_dir/no_extension_testfile"
./validate_xml.py -vvv -t 1 "$broken_dir/no_extension_testfile"
echo

echo "testing stdin"
./validate_xml.py - < "$data_dir/simple.xml"
./validate_xml.py < "$data_dir/simple.xml"
./validate_xml.py "$data_dir/simple.xml" - < "$data_dir/simple.xml"
echo

echo "Now trying non-xml files to detect successful failure:"
check_broken(){
    filename="$1"
    set +e
    ./validate_xml.py -vvv "$filename" ${@:2}
    result=$?
    set -e
    if [ $result = 2 ]; then
        echo "successfully detected broken xml in '$filename', returned exit code $result"
        echo
    #elif [ $result != 0 ]; then
    #    echo "returned unexpected non-zero exit code $result for broken xml in '$filename'"
    #    exit 1
    else
        echo "FAILED, returned unexpected exit code $result for broken xml in '$filename'"
        exit 1
    fi
}
# still works without the XML header
#sed -n '2,$p' "$data_dir/simple.xml" > "$broken_dir/simple.xml"
# break one from tag
sed -n 's/from/blah/; 2,$p' "$data_dir/simple.xml" > "$broken_dir/simple.xml"
check_broken "$broken_dir/simple.xml"
check_broken "$data_dir/test.yaml"
check_broken "$data_dir/test.json"
check_broken README.md
cat "$data_dir/simple.xml" >> "$broken_dir/multi-broken.xml"
cat "$data_dir/simple.xml" >> "$broken_dir/multi-broken.xml"
check_broken "$broken_dir/multi-broken.xml"
rm -fr "$broken_dir"
echo

echo "======="
echo "SUCCESS"
echo "======="

echo
echo
