#!/bin/sh
LINK=https://gitter.im/jpetazzo/workshop-20170322-sanjose
#LINK=https://dockercommunity.slack.com/messages/captains
#LINK=https://usenix-lisa.slack.com/messages/docker
sed "s,@@LINK@@,$LINK,g" >index.html <<EOF
<html>
<!-- Generated with index.html.sh -->
<head>
<meta http-equiv="refresh" content="0; URL='$LINK'" />
</head>
<body>
<a href="$LINK">$LINK</a>
</body>
</html>
EOF

