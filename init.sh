#!/bin/sh

export CONTAINER_IP=$(hostname -i)
echo $CONTAINER_IP
java -jar -DCONTAINER_IP=$CONTAINER_IP docker-kafka-streams-1.0.jar