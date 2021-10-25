# unit tests
# these are python based, and run catwalk via python client
# install the python environment with (one-off)
# pipenv install
# chmod +x run_tests.sh
# then issue ./run_tests.sh 

# compile catwalk and run tests

# cleanup first
rm -rf cw_server
rm -rf cw_webui
rm -rf cw_client
rm -rf nim_software
rm nim_software -rf
mkdir nim_software
cd nim_software
wget https://nim-lang.org/download/nim-1.4.8-linux_x64.tar.xz
tar -xf nim-1.4.8-linux_x64.tar.xz
NIMDIR="`pwd`/nim-1.4.8/bin"
#echo "$NIMDIR" >> $GITHUB_PATH

# test whether NIMDIR is on path; add if not
PATHCHECK=`echo $PATH | grep $NIMDIR`
if [ ${#PATHCHECK}==0 ]; then
  PATH=$PATH:"$NIMDIR"
else
  echo "nim already on path"
fi


nimble --version
cd ..
nimble -y build -d:release -d:danger -d:no_serialisation

# add CW_BINARY_FILEPATH to .env
rm .env -f
echo CW_BINARY_FILEPATH=\"`pwd`/cw_server\" > .env

# test    
pipenv run pytest test

# cleanup
#rm -rf cw_server
#rm -rf cw_webui
#rm -rf cw_client
#rm -rf nim_software

        