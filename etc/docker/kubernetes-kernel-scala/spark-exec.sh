#! /bin/bash
set -e

# If this is invoked for an executor, SPARK_EXECUTOR_ID will be set, otherwise invocation
# is for a driver.

if ! [ -z ${SPARK_EXECUTOR_ID+x} ]; then
	SPARK_CLASSPATH="$SPARK_HOME/jars/*"
	env | grep SPARK_JAVA_OPT_ | sed 's/[^=]*=\(.*\)/\1/g' > /tmp/java_opts.txt
	readarray -t SPARK_EXECUTOR_JAVA_OPTS < /tmp/java_opts.txt
	[[ -z ${SPARK_MOUNTED_CLASSPATH}+x} ]] || SPARK_CLASSPATH="$SPARK_MOUNTED_CLASSPATH:$SPARK_CLASSPATH"
	[[ -z ${SPARK_EXECUTOR_EXTRA_CLASSPATH+x} ]] || SPARK_CLASSPATH="$SPARK_EXECUTOR_EXTRA_CLASSPATH:$SPARK_CLASSPATH"
	[[ -z ${SPARK_EXTRA_CLASSPATH+x} ]] || SPARK_CLASSPATH="$SPARK_EXTRA_CLASSPATH:$SPARK_CLASSPATH"
	[[ -z ${HADOOP_CONF_DIR+x} ]] || SPARK_CLASSPATH="$HADOOP_CONF_DIR:$SPARK_CLASSPATH"
	[[ -z ${SPARK_MOUNTED_FILES_DIR+x} ]] || cp -R "$SPARK_MOUNTED_FILES_DIR/." .
	[[ -z ${SPARK_MOUNTED_FILES_FROM_SECRET_DIR+x} ]] || cp -R "$SPARK_MOUNTED_FILES_FROM_SECRET_DIR/." .

	set -x
    ${JAVA_HOME}/bin/java "${SPARK_EXECUTOR_JAVA_OPTS[@]}" -Dspark.executor.port=$SPARK_EXECUTOR_PORT -Xms$SPARK_EXECUTOR_MEMORY -Xmx$SPARK_EXECUTOR_MEMORY -cp "$SPARK_CLASSPATH" org.apache.spark.executor.CoarseGrainedExecutorBackend --driver-url $SPARK_DRIVER_URL --executor-id $SPARK_EXECUTOR_ID --cores $SPARK_EXECUTOR_CORES --app-id $SPARK_APPLICATION_ID --hostname $SPARK_EXECUTOR_POD_IP

else
	SPARK_CLASSPATH="$SPARK_HOME/jars/*"
	env | grep SPARK_JAVA_OPT_ | sed 's/[^=]*=\(.*\)/\1/g' > /tmp/java_opts.txt
	readarray -t SPARK_DRIVER_JAVA_OPTS < /tmp/java_opts.txt
	[[ -z ${SPARK_MOUNTED_CLASSPATH+x} ]] || SPARK_CLASSPATH="$SPARK_MOUNTED_CLASSPATH:$SPARK_CLASSPATH"
	[[ -z ${SPARK_SUBMIT_EXTRA_CLASSPATH+x} ]] || SPARK_CLASSPATH="$SPARK_SUBMIT_EXTRA_CLASSPATH:$SPARK_CLASSPATH"
	[[ -z ${SPARK_EXTRA_CLASSPATH+x} ]] || SPARK_CLASSPATH="$SPARK_EXTRA_CLASSPATH:$SPARK_CLASSPATH"
	[[ -z ${HADOOP_CONF_DIR+x} ]] || SPARK_CLASSPATH="$HADOOP_CONF_DIR:$SPARK_CLASSPATH"
	[[ -z ${SPARK_MOUNTED_FILES_DIR+x} ]] || cp -R "$SPARK_MOUNTED_FILES_DIR/." .
	[[ -z ${SPARK_MOUNTED_FILES_FROM_SECRET_DIR+x} ]] || cp -R "$SPARK_MOUNTED_FILES_FROM_SECRET_DIR/." .

	set -x
	$JAVA_HOME/bin/java "${SPARK_DRIVER_JAVA_OPTS[@]}" -cp "$SPARK_CLASSPATH" -Xms$SPARK_DRIVER_MEMORY -Xmx$SPARK_DRIVER_MEMORY -Dspark.driver.bindAddress=$SPARK_DRIVER_BIND_ADDRESS $SPARK_DRIVER_CLASS $SPARK_DRIVER_ARGS
fi
