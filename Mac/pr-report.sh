TMPFILE=$(mktemp)
echo "TMPFILE=$TMPFILE"
find ~/src -type d -depth 1 \( -name "aws-voyager*" -or -name "voyager-request-ui" \) -print -exec bash -c 'cd {} && /usr/local/bin/gh pr list && echo ---------' \; | tee $TMPFILE
mail -s "Dailiy PR Report" michael.fink@analysts.com < $TMPFILE
