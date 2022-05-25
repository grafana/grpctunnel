#!/bin/sh

DIR=$(dirname $0)
echo $DIR

cd $DIR

# run the server
# The server handles connecting the client with the target and transmitting between them.
(
    echo "Starting Proxy Server"
    go run ../cmd/server/server.go -tunnel_address 0.0.0.0:9876 -cert_file ./cert.pem -key_file ./key.pem
)&
SERVER_ID=$?

# run the client.  This is the component that runs with the Grafana instance.  It listens on a local TCP port
# and when a connection is made to that port it is forwarded via the Server to the target, which then forwards it
# on to the destination target.
(
    sleep 3
    echo "starting client"
    go run ../cmd/client/client.go -ca_file ./cert.pem -listen_addr 127.0.0.1:4321 -tunnel_server_address localhost:9876 -dial_target_type UNKNOWN -dial_target target1
)&
CLIENT_ID=$?

# run the target.  This is the component that runs in the customers environment.  The customer needs to define the
# targets that they want to expose within the target.cfg file.  For each target, a client needs to be run alongside the grafana instance.
(
    sleep 5
    echo "starting target"
    go run ../cmd/target/target.go -config_file ./target.cfg
)&

TARGET_ID=$?

wait

## If you open https://localhost:4321 in your browser, the connection will be proxied through to grafana.com