#!/bin/bash

BASE="https://lrms.loyolacollege.edu/studenterp"
COOKIE="cookies.txt"

echo "=== Fetching login page ==="

curl -s \
  -c "$COOKIE" \
  -b "$COOKIE" \
  "$BASE/" \
  -o login.html

echo
echo "=== CAPTCHA ==="

grep -A3 -B2 -i 'captcha__text' login.html

echo
read -p "Enter CAPTCHA shown above: " CAPTCHA
read -s -p "Enter password: " PASSWORD
echo

echo
echo "=== Login ==="

curl -s \
  -c "$COOKIE" \
  -b "$COOKIE" \
  -X POST \
  "$BASE/ajax/validateLogin.jsp" \
  -H 'Content-Type: application/x-www-form-urlencoded; charset=UTF-8' \
  -H 'X-Requested-With: XMLHttpRequest' \
  --data-urlencode 'registerno=26-PDS-002' \
  --data-urlencode "password=$PASSWORD" \
  --data-urlencode "captcha=$CAPTCHA"

echo
echo
echo "=== Attendance Summary ==="

curl -s \
  -b "$COOKIE" \
  -X POST \
  "$BASE/ajax/getAttendanceSummary.jsp" \
  -H 'X-Requested-With: XMLHttpRequest'

echo
echo
echo "=== Hour-wise Attendance ==="

curl -s \
  -b "$COOKIE" \
  -X POST \
  "$BASE/ajax/getHourWiseAttendance_new.jsp" \
  -H 'X-Requested-With: XMLHttpRequest'

echo
echo
echo "=== Internal Marks ==="

curl -s \
  -b "$COOKIE" \
  "$BASE/ajax/getsubjectInternalMarks.jsp?studentid=26-PDS-002" \
  -H 'X-Requested-With: XMLHttpRequest'

echo
echo
echo "=== Subjects ==="

curl -s \
  -b "$COOKIE" \
  -X POST \
  "$BASE/ajax/getStudentSubjects.jsp" \
  -H 'X-Requested-With: XMLHttpRequest'

echo
echo
echo "=== Profile ==="

curl -s \
  -b "$COOKIE" \
  "$BASE/ajax/getStudentProfile.jsp" \
  -H 'X-Requested-With: XMLHttpRequest'

echo