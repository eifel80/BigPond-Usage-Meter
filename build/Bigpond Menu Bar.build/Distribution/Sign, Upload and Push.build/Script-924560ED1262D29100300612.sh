#!/bin/bash
if [ $BUILD_STYLE = Distribution ]; then
	/usr/local/bin/git commit -a -m "Distribution Build";
	/usr/local/bin/git push;
fi
