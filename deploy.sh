#!/usr/bin/env bash
#******************************************************************************
#    Deploy Fortune-UI
#******************************************************************************
#
# DESCRIPTION
#    Deploys the fortune-ui app and necessary services
#
#
#==============================================================================
#
#==============================================================================

echo "*********************************************************************************************************"
echo "******************************************* Deploy fortune-ui *******************************************"
echo "**************************************** REQUIRES cf cli AND jq *****************************************"
echo ""

# Set variables
echo -n "App prefix ['random']> "
read APPPREFIX
if [ -z "$APPPREFIX" ]; then
    APPPREFIX="random"
fi

echo -n "Config Server name ['$APPPREFIX-fortunes-config-server']> "
read CONFIGSERVER
if [ -z "$CONFIGSERVER" ]; then
    CONFIGSERVER="$APPPREFIX-fortunes-config-server"
else
    CONFIGSERVER="$APPPREFIX-$CONFIGSERVER"
fi

echo -n "Service Registry name ['$APPPREFIX-fortunes-service-registry']> "
read SERVICEREGISTRY
if [ -z "$SERVICEREGISTRY" ]; then
    SERVICEREGISTRY="$APPPREFIX-fortunes-service-registry"
else
    SERVICEREGISTRY="$APPPREFIX-$SERVICEREGISTRY"
fi

echo -n "Circuit Breaker Dashboard name ['$APPPREFIX-fortunes-circuit-breaker-dashboard']> "
read CIRCUITBREAKER
if [ -z "$CIRCUITBREAKER" ]; then
    CIRCUITBREAKER="$APPPREFIX-fortunes-circuit-breaker-dashboard"
else
    CIRCUITBREAKER="$APPPREFIX-$CIRCUITBREAKER"
fi

echo -n "Cloud Bus name ['$APPPREFIX-fortunes-cloud-bus']> "
read CLOUDBUS
if [ -z "$CLOUDBUS" ]; then
    CLOUDBUS="$APPPREFIX-fortunes-cloud-bus"
else
    CLOUDBUS="$APPPREFIX-$CLOUDBUS"
fi

./mvnw clean package

CF_API=`cf api | head -1 | cut -c 25-`

# Deploy services
if [[ $CF_API == *"api.run.pivotal.io"* ]]; then
# Uncomment the following section if you'd like to use PCF managed DB.
    cf create-service p-config-server trial $CONFIGSERVER -c '{"git": { "uri": "https://github.com/bernardpark/fortune-teller-config", "label": "master" } }'
    cf create-service p-service-registry trial $SERVICEREGISTRY
    cf create-service p-circuit-breaker-dashboard trial $CIRCUITBREAKER
    cf create-service cloudamqp lemur $CLOUDBUS
else
    if [ ! -z "`cf m | grep "p-config-server"`" ]; then
      export service_name="p-config-server"
      export config_json="{\"git\": { \"uri\": \"https://github.com/bernardpark/fortune-teller-config\", \"label\": \"master\" } }"
    elif [ ! -z "`cf m | grep "p\.config-server"`" ]; then
      export service_name="p\.config-server"
      export config_json="{\"skipSslValidation\": true, \"git\": { \"uri\": \"https://github.com/bernardpark/fortune-teller-config\", \"label\": \"master\" } }"
    else
      echo "Can't find SCS Config Server in marketplace. Have you installed the SCS Tile?"
      exit 1;
    fi

# Uncomment the following section if you'd like to use PCF managed DB.
    echo "$config_json"
    cf cs $service_name standard $CONFIGSERVER -c "$config_json"
    cf cs p-service-registry standard $SERVICEREGISTRY
    cf cs p-circuit-breaker-dashboard standard $CIRCUITBREAKER
    cf create-service p.rabbitmq single-node-3.7 $CLOUDBUS
fi

# Prepare config file to set TRUST_CERTS value
echo "app_prefix: $APPPREFIX" > vars.yml
echo "config_server: $CONFIGSERVER" >> vars.yml
echo "service_registry: $SERVICEREGISTRY" >> vars.yml
echo "circuit_breaker: $CIRCUITBREAKER" >> vars.yml
echo "cloud_bus: $CLOUDBUS" >> vars.yml
echo "cf_trust_certs: $CF_API" >> vars.yml

# Wait until services are ready
while cf services | grep 'create in progress'
do
  sleep 20
  echo "Waiting for services to initialize..."
done

# Check to see if any services failed to create
if cf services | grep 'create failed'; then
  echo "Service initialization - failed. Exiting."
  return 1
fi
echo "Service initialization - successful"

# Push apps
cf push --vars-file vars.yml
