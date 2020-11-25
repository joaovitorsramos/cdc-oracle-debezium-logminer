cd instantclient
cp ojdbc8.jar xstreams.jar /kafka/libs
LD_LIBRARY_PATH=/kafka/instantclient/
export LD_LIBRARY_PATH=/instantclient/:$LD_LIBRARY_PATH