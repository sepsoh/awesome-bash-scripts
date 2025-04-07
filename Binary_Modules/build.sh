mkdir bin 2>/dev/null
exception_dirs="bin" #insert '|' between exceptions to make grep -E work
for dir in $(ls -F | grep '/' | grep -v -E "$exception_dirs"); do
	(
	cd $dir

	expected_bin_name=$(pwd | sed -e 's/.*\///')

	go build ${expected_bin_name}.go
	if [ "$?" != "0" ];then
		exit 1
	fi

	mv $expected_bin_name ../bin/
	)

done


