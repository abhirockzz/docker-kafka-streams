A [Kafka Streams](https://kafka.apache.org/documentation/streams) based microservice which is similar to one of my [previous examples](https://github.com/abhirockzz/kafka-streams-example), but with the following differences

- the Kafka streams based microservice will now run on a Docker container
- you can horizontally scale out your processing by starting new Docker containers

Please [refer to this](https://github.com/abhirockzz/kafka-streams-example/blob/master/README.md) to get an idea of the other aspects 

- A producer application continuously emits CPU usage metrics into a Kafka topic (cpu-metrics-topic)	
- The consumer is a Kafka Streams application which uses the Processor (low level) Kafka Streams API to calculate the [Cumulative Moving Average](https://en.wikipedia.org/wiki/Moving_average#Cumulative_moving_average) of the CPU metrics of each machine
- Consumers can be horizontally scaled - the processing work is distributed amongst many nodes and the process is elastic and flexible thanks to Kafka Streams (and the fact that it leverages Kafka for fault tolerance etc.)
- Each instance has its own (local) state for the calculated average. A custom REST API has been (using Jersey JAX-RS implementation) to tap into this state and provide a unified view of the entire system (moving averages of CPU usage of all machines)


### To try things out...

- Start the Kafka broker. Configure `num.partitions` in Kafka broker `server.properties` file to 5 (to experiment with this application)
- [Clone the producer application](https://github.com/abhirockzz/kafka-streams-example/tree/master/kafka-producer) & build it `mvn clean install`
- Trigger producer application - `java -jar kafka-cpu-metrics-producer.jar`. It will start emitting records to Kafka
- Containerize - `docker build -t abhirockzz/docker-kafka-streams` (you can obviously choose a repo name of your choice)
- Start one instance of consumer application - `docker run --rm --name consumer-1 -it -P -e KAFKA_BROKER=<kafka broker host:port> -e ZOOKEEPER=<zookeeper host:port> abhirockzz/docker-kafka-streams`. It will start calculating the moving average of machine CPU metrics
- We used `-P` option with `docker run`, so a random host port will be bound with the application port (which is hard coded to 8080, but it shouldn't matter). To find the port of the current container execute `docker port consumer-1` (where `consumer-1` is the name of the container)
- Access the metrics on this instance - `http://docker-ip:port/metrics`  e.g. `http://192.168.99.100:32768/metrics`

Sample output - https://gist.github.com/abhirockzz/48e89873ae23c93d0a5cc721c87cc536

- Start another instance of consumer application - `docker run --rm --name consumer-2 -it -P -e KAFKA_BROKER=<kafka broker host:port> -e ZOOKEEPER=<zookeeper host:port> abhirockzz/docker-kafka-streams`. You will notice that Kafka Streams re-distributes the processing load

- You can also search for metrics for a specific machine ID `http://docker-ip:port/metrics/<machine-ID>` e.g. `http://192.168.99.100:32768/metrics/machine-4`

Sample output - https://gist.github.com/abhirockzz/2ca2297fbc9aec269d31707f61b4c45e

You can keep increasing the number of instances such that they are less than or equal to the number of partitions of your Kafka topic

### Notes... 

- Having more instances than number of partitions is not going to have any effect on parallelism and that instance will be inactive until any of the existing instance is stopped
- The inter-container discovery mechanism uses the internal IP of the Docker container (in `init.sh`) - there is no explicit linking or network related configurations which (logically) attach these Docker containers together. This is just for simplicity and won't work in a multi-host setup
