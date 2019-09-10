# Fortune Teller MicroServices - Fortune UI

## Overview
This repository is a microservice of the larger [Fortune Teller Application](https://github.com/msathe-tech/fortune-teller) guided as a workshop. This is a JavaScript UI layer using Spring MVC to git the [Fortune API](https://github.com/bernardpark/fortune-teller-service) "backend for frontend".

## Service Registry
By including spring-cloud-services-starter-service-registry, your application will now be registered in your Service Registry service instance in Pivotal Cloud Foundry.

## Spring Cloud Configuration
You should also notice the spring-cloud-services-starter-config-client dependency. This allows your application to bind to the Pivotal Cloud Config Server service to consumer external configuration.

## Spring Cloud Circuit Breaker
Another dependency included in this application is the spring-cloud-services-starter-circuit-breaker dependency. This allows the use of Hystrix to implement circuit breaking for Cloud Native practices.

### Coding Exercise 1 - Registering your Application
Take a look at `src/main/resources/bootstrap.yml`. This properties file, to be read before your application.yml file, defines the name of this application when it is registered in your Service Registry. You should remember this from the lab where you deployed your Fortune Service application. This is the same drill. For this exercise, add the `spring.application.name` property in yml fashion and give it the name `fortune-ui`.

**bootstrap.yml**

```
spring:
  application:
    name: fortune-api
```

Save your file.

### Coding Exercise 2 - Make your Application a Configuration Client
This application will pull configuration from a remote server. In our case, we will be using the Pivotal Cloud Config service, which will consume from a remote Github repository. To enable your application as a Configuration Client, annotate the `Application.java` class with `@EnableDiscoveryClient`.

**Application.java**

```
@SpringBootApplication
@EnableDiscoveryClient
public class Application {
...
```
Save your file.

### Coding Exercise 3 - Consume an External Configuration

Now that we can consume external configuration, let's do so in a properties class. In your `FortuneProperties.java` class, add the `@ConfigurationProperties` annotation while referring to prefix `api`. This will tell your class to consume configuration as a Configuration Client application, and apply the prefix `api` as default. You should notice that your configuration repository follows this property prefix. In particular, notice the `api.fallbackFortune` and `api.serviceURL` properties. These are the same as the class variables that are provided for you.
Also make sure you add the `@RefreshScope` annotation. This will allow you to refresh this bean with updated configuration by posting to the Spring Actuator refresh endpoint.

**FortuneProperties.java**

```
@ConfigurationProperties(prefix = "service")
@RefreshScope
public class FortuneProperties {
```

Save your file.

### Coding Exercise 4 - Add a Service Class
This application will require a service class to execute a Rest call to the Fortune API application. If you don't have the Fortune API application deployed, don't worry. We will implement a circuit breaker so that we are not dependent on it. You can review the lab to deploy the Fortune Service [here](https://github.com/bernardpark/fortune-teller-api/tree/master-lab).

Open the `FortuneService.java` class. Annotate the class with `@Service` so that we can reference this bean with `@Autowired` in other classes. Also annotate the class with `@EnableConfigurationProperties` by referencing the `FortuneProperties.class` so that it can consume configuration properties from the properties class we just created.

**ApiService.java**

```
@Service
@EnableConfigurationProperties(FortuneProperties.class)
public class ApiService {
...
```

Now, create class variables for the `FortuneProperties` class and `RestTemplate` class to use in our service methods. Remember, we can autowire the `FortuneProperties` class because we had annotated it with `@ConfigurationProperties(prefix = "api")`. We can do the same with `RestTemplate` as it is already defined as a bean in `Application.java`. Once those class variables have been defined, create a simple method that this application will primarily use to call the Fortune Service application. We can do so by calling the `RestTemplate.getForObject()` method while referencing the Fortune API URL through the `FortuneProperties` class, and appending the `random` endpoint. **Also note in that your configuration repository should define the Fortune API URL with the naming convention of "//" + "APPLICATION_NAME_IN_REGISTRY"**

**ApiService.java**

```
...
    @Autowired
    FortuneProperties fortuneProperties;

    @Autowired
    RestTemplate restTemplate;

        public Fortune randomFortune() {
        String randomFortuneURL = fortuneProperties.getServiceURL().concat("/random");
        return restTemplate.getForObject(randomFortuneURL, Fortune.class);
    }
...
```

Save your file.

### Coding Exercise 5 - Add a Circuit Breaker
It was mentioned earlier that this application will not be dependent to the Fortune Service application. We will make this happen with circuit breaking. In the same `ApiService.java` class, add the `@HystrixCommand` annotation while specifying the name of the fallback method. In parallel, create the fallback method that returnes a fallback fortune to avoid errors and failures. If this application catches any errors during the `randomeFortune()` method, it will fallback and execute the fallback method instead.

**ApiService.java**

```
...
    @HystrixCommand(fallbackMethod = "fallbackFortune")
    public Fortune randomFortune() {
        String randomFortuneURL = fortuneProperties.getServiceURL().concat("/random");
        return restTemplate.getForObject(randomFortuneURL, Fortune.class);
    }

    private Fortune fallbackFortune() {
        return new Fortune(42L, fortuneProperties.getFallbackFortune());
    }
...
```

Save your file.

Make sure your `Application.java` also includes the `@EnableCircuitBreaker` annotation as well.

**Application.java**

```
@SpringBootApplication
@EnableDiscoveryClient
@EnableCircuitBreaker
public class Application {
...
```
Save your file.

### Coding Exercise 6 - Code in Advance
Now, let's try to consume a different API endpoint that does not yet exist. If you remember from the [Fortune Service](https://github.com/bernardpark/fortune-teller-service/tree/master-lab) application, we had two methods exposed. One was to return a random fortune, which we are calling from the UI -> API -> Service, and another to return all fortunes. If you also remember from the [Fortune API](https://github.com/bernardpark/fortune-teller-api/tree/master-lab), we did not include an API call to the second method. In the UI, we will attempt to reach out to the API to fetch all fortunes, which will not be available. Hence, implementing a circuit breaker and a fallback method will gracefully handle the request when it fails. This practice shows how different microservices can be built in parallel without crippling dependencies.

Create another method named `fortunes()` and apply the same practice to implement a Rest call to the API, and adding a fallback method.

**ApiService.java**

```
...
    @HystrixCommand(fallbackMethod = "fallbackFortunes")
    public Fortune fortunes() {
        String randomFortuneURL = fortuneProperties.getApiURL().concat("/fortunes");
        return restTemplate.getForObject(randomFortuneURL, Fortune.class);
    }

    private Fortune fallbackFortunes() {
        return new Fortune(42L, fortuneProperties.getFallbackFortune());
    }
...
```

### Coding Exercise 7 - Add REST Endpoint
Now that we have a repository method, we need a way for an application user to execute the method. Open your `UiController.java` class and view its annotations. The `@RestController` annotation tells Spring that this class will define our REST endpoints. We also `@Autowired` the `UiService` bean so that it can be referenced in this class. Remember, we can autowire this bean because we had added the `@Service` annotation,.

Create a method called `randomFortune()` to call the `ApiService.randomFortune()` method we coded earlier. Annotate with the `@RequestMapping` annotation, specifying the endpoint to map to `/random`. Do the same to create a method called `fortunes()`, with a `@RequestMapping` to `/fortunes`.

**ApiController.java**

```
...
    @RequestMapping("/random")
    public Fortune randomFortune() {
        return service.randomFortune();
    }

    @RequestMapping("/fortunes")
    public Fortune fortunes() {
        return service.fortunes();
    }
...
```

Save your file.

## Deploying the Application
Build and deploy application on current 'cf target'

1. Build your applications with Maven

```
mvn clean package
```

1. Create the necessary services on Pivotal Cloud Foundry. For this application, we will need a Config Server, a Circuit Breaker Dashboard, and a RabbitMQ instance (RabbitMQ will act as a service bus so that `/actuator/refresh` posts can be cascaded to all applications with `@RefreshScope` beans. If you don't already have a Service Registry, create that too.

One thing to note is that the Config Server service needs to be created with parameters to consume a backend git repository. You can do so by adding a JSON text with the `-c` flag.

```
# Repeat for all required services

# View available services
cf marketplace
# View service details
cf marketplace -s $SERVICE_NAME
# Create the service (config server)
cf create-service $SERVICE_NAME $SERVICE_PLAN $YOUR_SERVICE_NAME -c '{"git": { "uri": "https://github.com/$GITHUB/$REMOTE_CONFIG_REPO", "label": "$BRANCH" } }'
# Create the service (all others)
cf create-service $SERVICE_NAME $SERVICE_PLAN $YOUR_SERVICE_NAME
```

1. Draft your `manifest.yml` in the root directory. Note that the variables, enclosed in double parentheses (()), will contain the key of each variable. We will create the variable file shortly.

```
---
applications:
- name: ((app_name))
  memory: 1024M
  path: ./target/fortune-teller-ui-0.0.1-SNAPSHOT.jar
  instances: 1
  services:
  - ((config_server))
  - ((service_registry))
  - ((circuit_breaker))
  - ((cloud_bus))
  env:
    TRUST_CERTS: ((cf_trust_certs))
```

1. Draft your `vars.yml` file in the root directory. Notice that the keys to all variables are referenced in the `manifest.yml` file we just created. You will also need to know your PCF API endpoint. You can find this by visiting Apps Manager -> Tools -> `Login to the CLI` box, or by running the command `cf api | head -1 | cut -c 25-`.

```
app_name: $YOUR_APP_NAME
config_server: $YOUR_CONFIG_SERVICE_NAME
service_registry: $YOUR_SERVICE_REGISTRY_NAME
circuit_breaker: $YOUR_CIRCUIT_BREAKER_DASHBOARD_NAME
cloud_bus: $YOUR_CLOUD_BUS_NAME
cf_trust_certs: $YOUR_PCF_API_ENDPOINT
```

1. Push your application.

```
cf push
```

Examine the manifest.yml file to review the application deployment configurations and service bindings.

## Test the application

### Test the UI endpoint - existing API backend
1. Make sure the [Fortune API](https://github.com/bernardpark/fortune-teller-api/tree/master_lab) is deployed in the same environment.
1. Visit `https://$YOUR_UI_ENDPOINT/random`
1. Notice the random fortune returned
1. Refresh the page
1. Notice another random fortune returned

### Test the UI endpoint - unavailable UI
1. Make sure the [Fortune API](https://github.com/bernardpark/fortune-teller-api/tree/master_lab) is deployed in the same environment.
1. Visit `https://$YOUR_UI_ENDPOINT/fortunes`
1. Notice the random fortune returned
1. Refresh the page
1. Notice another random fortune returned


### Test Circuit Breaker
1. Stop your [Fortune API](https://github.com/bernardpark/fortune-teller-api/tree/master_lab) (ex. `cf stop $YOUR_API_APP_NAME`)
1. Visit `https://$YOUR_UI_ENDPOINT/random`
1. Notice the default fallback message

### Test Cloud Config
1. Make a change to you `application.yml` with a new fallback message
1. Refresh your application beans using the actuator endpoint (ex. `curl -k https://$YOUR_UI_ENDPOINT/actuator/refresh -X POST`)
1. Visit `https://$YOUR_UI_ENDPOINT/random`
1. Notice the changed default fallback message

## Return to Workshop Respository
[Fortune Teller Workshop](https://github.com/msathe-tech/fortune-teller/README.md#lab4-add-a-ui)

## Authors
* **Bernard Park** - [Github](https://github.com/bernardpark)
* **Madhav Sathe** - [Github](https://github.com/msathe-tech)
