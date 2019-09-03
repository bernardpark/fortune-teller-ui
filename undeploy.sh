#!/bin/bash

# Set variables
echo -n "App prefix ['random']> "
read APPPREFIX
if [ -z "$APPPREFIX" ]; then
    APPPREFIX="random"
fi

echo -n "Database name ['$APPPREFIX-fortunes-db']> "
read DATABASE
if [ -z "$DATABASE" ]; then
    DATABASE="$APPPREFIX-fortunes-db"
else
    DATABASE="$APPPREFIX-$DATABASE"
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

# delete apps
cf delete $APPPREFIX-fortune-api -f
cf delete $APPPREFIX-fortune-service -f
cf delete $APPPREFIX-fortune-ui -f
cf delete $APPPREFIX-fortune-gateway -f

# delete services
cf delete-service $DATABASE -f
cf delete-service $CONFIGSERVER -f
cf delete-service $SERVICEREGISTRY -f
cf delete-service $CIRCUITBREAKER -f
cf delete-service $CLOUDBUS -f

# delete orgphaned routes
cf delete-orphaned-routes -f
